# Architecture du projet

C'est le fichier le plus important de toute la prépa. Si tu maîtrises ça, tu défends 80% du projet.

## La big picture en 30 secondes

Le projet implémente un **test A/B** entre deux versions d'une même app :
- Version A en Spring Boot (Java)
- Version B en Django (Python)

Nginx route les utilisateurs alternativement vers A ou B sur la route `/test`. Tout ça tourne en local via Docker Compose **et** en prod sur Azure via un pipeline CI/CD GitLab.

## Les 4 couches du projet

```
┌────────────────────────────────────────────┐
│  Couche 1 : Applications                   │  ← code école (Spring Boot + Django)
│  ── spring-boot/   └── django/             │
├────────────────────────────────────────────┤
│  Couche 2 : Routing (Nginx)                │  ← NOUS, P2 + P6
│  ── nginx/ (local)  └── nginx-azure/ (prod)│
├────────────────────────────────────────────┤
│  Couche 3 : CI/CD (GitLab)                 │  ← NOUS, P3 + P5
│  ── .gitlab-ci.yml                         │
├────────────────────────────────────────────┤
│  Couche 4 : Infrastructure (Azure)         │  ← NOUS, P4
│  ── terraform/                             │
└────────────────────────────────────────────┘
```

🎯 **À retenir** : *« Le projet a 4 couches : les apps (couche métier, code de l'école), le routing Nginx (notre Partie 2 et 6), le pipeline CI/CD (Parties 3 et 5), et l'infra Azure (Partie 4). Chaque couche est un sujet du cours DevOps. »*

## Flow #1 — Déroulement en LOCAL (docker-compose)

```
  User → http://localhost/test
            │
            ▼
   ┌──────────────────┐
   │  Container nginx  │ ← image nginx:alpine + nginx/nginx.conf
   │  port 80          │
   └─────────┬────────┘
             │ proxy_pass http://apps-ab/
             │ (round-robin Nginx)
       ┌─────┴─────┐
       ▼           ▼
  ┌─────────┐  ┌─────────┐
  │ spring  │  │ django  │
  │ :8080   │  │ :8000   │
  └─────────┘  └─────────┘
   (Container)  (Container)
   
  Tous connectés par le réseau Docker "ab-network" (bridge)
```

**Ce que ça veut dire concrètement :**
- L'utilisateur tape `http://localhost/test` dans son navigateur
- Nginx (sur port 80) reçoit la requête
- Il décide d'envoyer vers Spring (port 8080 du conteneur) ou Django (port 8000) en alternance via le **round-robin** par défaut de la directive `upstream`
- Le `proxy_pass http://apps-ab/` avec le `/` à la fin réécrit l'URL : `/test` devient `/` côté backend → les apps servent leur page d'accueil
- Les 3 conteneurs se voient grâce au **réseau partagé `ab-network`** déclaré dans `docker-compose.yml`

⚠️ **Piège potentiel** : si le prof demande *« qu'est-ce qui fait l'alternance A/B ? »* — c'est le **round-robin** par défaut de Nginx, pas une logique custom. Ne pas dire « j'ai codé un randomizer », c'est faux.

## Flow #2 — Déroulement en PROD (push → pipeline → Azure)

```
   git push origin main
        │
        ▼
   ┌──────────────────────┐
   │  GitLab CI déclenche │
   │  un pipeline auto    │
   └──────────┬───────────┘
              │
              ▼
   Le pipeline tourne sur le GitLab Runner (un conteneur Docker
   sur la machine de Rachid, enregistré auprès de GitLab)
   
   ┌──────────────────────────────────────────────────────┐
   │ Stage build : compile spring + install deps django   │
   │ Stage test  : mvn test + python manage.py test       │
   │ Stage deploy: docker build + push images vers ACR    │
   │ Stage update: az webapp restart sur les 2 App Services│
   └──────────────────────────────────────────────────────┘
              │
              ▼
   ┌──────────────────────────────────────────────────────┐
   │  Azure infrastructure (créée par Terraform en P4)    │
   │  ── Container Registry (ACR) : stocke les images     │
   │  ── App Service Spring : pull image, expose en HTTPS │
   │  ── App Service Django  : idem                       │
   └──────────────────────────────────────────────────────┘
              │
              ▼
   User → https://app-spring-66045.azurewebsites.net
   User → https://app-django-66045.azurewebsites.net
   (ou via le nginx-azure sur /test pour l'A/B testing)
```

**Ce que ça veut dire :**
- Chaque `git push` déclenche le pipeline automatiquement
- Le pipeline build les images Docker, les pousse dans le registry Azure (ACR)
- Puis il restart les App Services qui pullent les nouvelles images
- Et hop, les apps sont à jour en prod

🎯 **À retenir** : *« Le déploiement est entièrement automatisé via le pipeline GitLab. Un push sur main déclenche : compile, test, build des images Docker, push vers Azure Container Registry, et restart des App Services. »*

## Connexions entre les couches

### Comment Nginx (P2) se connecte aux apps localement
- Via le **réseau Docker `ab-network`** déclaré dans `docker-compose.yml`
- Dans le réseau Docker, les conteneurs se résolvent par **nom de service** (`spring-boot`, `django`)
- Nginx dans son conf utilise ces noms : `upstream apps-ab { server spring-boot:8080; server django:8000; }`

### Comment le pipeline (P3-P5) se connecte à Azure
- Via les **5 variables CI configurées dans GitLab** (`ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`, `ACR_NAME`)
- Ces variables contiennent les credentials d'un **Service Principal Azure** créé spécialement pour la CI
- Les jobs du pipeline les utilisent pour `docker login` (vers ACR) et `az login --service-principal` (pour restart App Services)

### Comment les App Services (P4) pullent les images d'ACR
- Chaque App Service a une **identité managée** (`azurerm_user_assigned_identity`)
- Cette identité a le rôle **AcrPull** sur l'ACR (`azurerm_role_assignment`)
- Quand l'App Service démarre, il s'authentifie automatiquement avec son identité et pull l'image
- C'est le bloc `container_registry_use_managed_identity = true` dans `azurerm_linux_web_app` qui active ça

⚠️ **Piège potentiel** : *« pourquoi tu n'utilises pas le Service Principal aussi pour le pull d'images ? »* → réponse : le SP sert au pipeline (push), l'identité managée sert au runtime (pull). Deux identités, deux usages, séparation des responsabilités.

## Décisions de design notables

### Multi-stage Dockerfile pour Spring Boot
**Choix** : Maven (build) → JRE Alpine (runtime)
**Pourquoi** : l'image finale n'embarque pas Maven ni le JDK complet, juste la JRE → poids divisé par ~3
**Alternative** : tout faire dans une seule image avec maven + java → image lourde
**Référence** : vu en TD 03 exo 4

### Single-stage Dockerfile pour Django
**Choix** : python:3.12-alpine direct
**Pourquoi** : Python n'a pas de phase de compilation au sens Java, pas de multi-stage utile
**Alternative** : aurait pu utiliser une image plus complète (`python:3.12-slim`), mais alpine = plus léger

### `PORT` au lieu de `WEBSITES_PORT` dans App Service
**Choix** : variable d'env `PORT` (et non `WEBSITES_PORT`) dans `app_settings`
**Pourquoi** : TD 08 mentionne explicitement qu'Azure a changé sa gestion, désormais c'est `PORT` qui marche
**Alternative** : `WEBSITES_PORT` aurait causé l'erreur « le serveur écoute sur le mauvais port »

### Service Principal vs Managed Identity
**Choix** : 2 identités différentes
- Service Principal : utilisé par le pipeline (push d'images, restart)
- Managed Identity : utilisée par les App Services (pull d'images depuis ACR)
**Pourquoi** : séparation des responsabilités, moindre privilège — chaque identité a juste ce qu'il lui faut
**Référence** : Service Principal vu en TD 09 page 14, Managed Identity vu en TD 08

### Région Azure `francecentral`
**Choix** : `francecentral` au lieu de `westeurope` (défaut TD 09)
**Pourquoi** : Azure for Students restreint les régions disponibles. La policy assignment listait `francecentral, spaincentral, germanywestcentral, austriaeast, italynorth`. France central = le plus proche de Bruxelles.
**Alternative** : `westeurope` aurait été refusée par la policy → `terraform apply` aurait crashé.

### Runner Docker partagé (volume `/var/run/docker.sock`)
**Choix** : runner Docker avec socket Docker hôte monté en volume
**Pourquoi** : permet aux jobs du pipeline de faire `docker build` / `docker push` en utilisant le daemon Docker de la machine hôte
**Alternative** : Docker-in-Docker (DinD) — plus complexe à configurer, perfs moindres
**Référence** : TD 07 page 21

## Mini-récap

| Question | Réponse |
|---|---|
| Combien de couches dans le projet ? | 4 : apps, routing, CI/CD, infra |
| Qui fait l'alternance A/B ? | Le round-robin par défaut de la directive `upstream` de Nginx |
| Comment Nginx joint les apps en local ? | Via le réseau Docker partagé `ab-network` + résolution par nom de service |
| Comment le pipeline s'authentifie à Azure ? | Via un Service Principal + 5 variables CI dans GitLab |
| Comment les App Services pullent leur image ? | Via une identité managée Azure avec rôle AcrPull sur l'ACR |
| Pourquoi `PORT` et pas `WEBSITES_PORT` ? | Azure a changé sa gestion des conteneurs, TD 08 le précise |
| Pourquoi multi-stage pour Spring Boot ? | Image finale légère (JRE Alpine au lieu de JDK+Maven) |
| Pourquoi pas DinD pour le pipeline Docker ? | Plus complexe, on utilise le socket Docker hôte (TD 07 p.21) |
| Pourquoi `francecentral` et pas `westeurope` ? | Azure for Students restreint les régions, `westeurope` refusée par policy |
| Service Principal vs Identité managée ? | SP = pipeline (push), Identité = runtime App Service (pull). Séparation. |
