# Tour du propriétaire — la carte du projet

## La règle d'or pour savoir quoi expliquer

| Origine du fichier | Tu dois le défendre ? |
|---|---|
| Donné par l'école (`spring-boot/src/`, `django/demo/`, `django/manage.py`, `spring-boot/pom.xml`, etc.) | ❌ Non, c'est leur code |
| Le fichier `alwaysdata` à la racine | ❌ Non, le prof l'a mis lui-même |
| **Tout ce qu'on a écrit** (Dockerfile, docker-compose, nginx.conf, .gitlab-ci.yml, terraform/*, README, .gitignore) | ✅ **OUI, à fond** |

Si le prof pointe un fichier de l'école, tu peux dire « c'est le code applicatif fourni par l'école, je n'ai pas touché ». Si il pointe un fichier qu'on a écrit, il attend une vraie explication.

## Structure du dépôt (vue d'oiseau)

```
projet/
├── spring-boot/              ← Version A de l'app (Java Spring Boot)
│   ├── src/                  ← (école) code Java
│   ├── pom.xml               ← (école) config Maven
│   ├── mvnw, mvnw.cmd        ← (école) wrapper Maven
│   ├── Dockerfile            ← NOUS : conteneurise l'app (multi-stage)
│   └── .dockerignore         ← NOUS : exclut les fichiers inutiles du build
│
├── django/                   ← Version B de l'app (Python Django)
│   ├── demo/                 ← (école) app Django principale
│   ├── djangoAbTesting/      ← (école) config Django
│   ├── manage.py             ← (école) CLI Django
│   ├── requirements.txt      ← (école) dépendances Python
│   ├── Dockerfile            ← NOUS : conteneurise l'app
│   └── .dockerignore         ← NOUS
│
├── nginx/                    ← Reverse proxy LOCAL (Partie 2)
│   ├── Dockerfile            ← NOUS : image nginx custom
│   └── nginx.conf            ← NOUS : upstream + route /test
│
├── nginx-azure/              ← Reverse proxy AZURE (Partie 6)
│   ├── Dockerfile            ← NOUS : même base mais pour la prod
│   └── nginx.conf            ← NOUS : upstream pointe sur les URLs Azure
│
├── terraform/                ← Infrastructure as code (Partie 4)
│   ├── providers.tf          ← NOUS : déclare le provider azurerm
│   ├── variables.tf          ← NOUS : 9 variables (région, noms ressources, etc.)
│   ├── main.tf               ← NOUS : 7 ressources Azure
│   ├── outputs.tf            ← NOUS : 3 outputs (URLs)
│   └── .terraform.lock.hcl   ← NOUS : pin de version du provider
│
├── docker-compose.yml        ← NOUS : orchestre les 3 services locaux
├── .gitlab-ci.yml            ← NOUS : pipeline CI/CD (8 jobs sur 4 stages)
├── .gitignore                ← NOUS : exclut artefacts, états, secrets
├── README.md                 ← NOUS : doc d'usage
└── alwaysdata                ← (prof) sous-domaine AlwaysData de Rachid (legacy)
```

## Le fichier `alwaysdata` — anecdote à connaître

C'est un fichier texte d'une ligne (`rachid9876.alwaysdata.net`) que le prof a placé dans le dépôt au tout début du semestre. Il sert de **fallback** : si un étudiant ne peut pas avoir Azure, il déploie sur AlwaysData et ce fichier indique son sous-domaine.

Dans ton cas, tu as Azure (via Azure for Students), donc tu n'as pas utilisé AlwaysData. Le fichier reste là parce que c'est le prof qui l'a mis, on ne supprime pas un fichier qu'il a posé.

🎯 **À retenir** : si le prof te demande « c'est quoi ce fichier `alwaysdata` ? », réponds : *« c'est le sous-domaine AlwaysData que vous m'aviez fait poser en début de semestre comme fallback au cas où Azure ne marcherait pas. J'ai eu accès à Azure for Students donc je l'ai utilisé pour P4-P6, mais j'ai laissé le fichier en place puisque c'est vous qui l'aviez ajouté. »*

## Vue par partie du projet

### Partie 1 — Conteneurisation
**Fichiers** : `spring-boot/Dockerfile`, `django/Dockerfile`, `docker-compose.yml` (version initiale), `spring-boot/.dockerignore`, `django/.dockerignore`, `.gitignore`, `README.md`
**Tag** : `conteneurisation`
**Commit principal** : `0a91fa3`

### Partie 2 — Nginx local A/B
**Fichiers** : `nginx/Dockerfile`, `nginx/nginx.conf`, `docker-compose.yml` (avec service nginx + réseau partagé)
**Tag** : `nginx`
**Commits** : `54bdeb4` (ajout nginx) + `83453c0` (integration compose)

### Partie 3 — Pipeline CI
**Fichiers** : `.gitlab-ci.yml` (avec stages `build` et `test`)
**Tag** : `pipeline-ci`
**Commits** : `8453efa` (jobs compile) + `73b2d4c` (jobs tests)

### Partie 4 — Infrastructure Azure (Terraform)
**Fichiers** : `terraform/providers.tf`, `variables.tf`, `main.tf`, `outputs.tf`, `.terraform.lock.hcl`
**Tag** : `infrastructure`
**Commits** : `1deded8` (init + resource_group) + `202ae3e` (ACR + App Services)

### Partie 5 — Déploiement automatisé
**Fichiers** : `.gitlab-ci.yml` (ajout stages `deploy` et `update`)
**Tag** : `deploiement`
**Commits** : `f735189` (push images vers ACR) + `89b5b0e` (restart App Services)

### Partie 6 — Nginx Azure
**Fichiers** : `nginx-azure/Dockerfile`, `nginx-azure/nginx.conf`
**Tag** : `nginx-azure`
**Commit** : `cc9997a`

## Navigation IDE rapide

Dans VS Code, pour cliquer vite vers un fichier pendant la défense :
- **Ctrl+P** puis tape : `Dockerfile` / `nginx.conf` / `main.tf` / `.gitlab-ci.yml` / `compose`
- VS Code te propose les chemins, tu cliques

Si le prof dit *« montre-moi ton Dockerfile Spring Boot »* :
- Ctrl+P → tape `spring`, le `spring-boot/Dockerfile` apparaît en haut → Enter

Entraîne-toi à faire ça **sans réfléchir**. Le jour J, hésiter 20 secondes sur la navigation IDE c'est 20 secondes de stress en plus.

## Mini-récap

| Question | Réponse |
|---|---|
| Qui a écrit le code des apps Spring Boot et Django ? | L'école, c'est le code applicatif fourni en début de semestre |
| Qui a écrit le `nginx.conf`, le `Dockerfile`, le `.gitlab-ci.yml`, le `terraform/main.tf` ? | Nous (toi) — c'est tout le travail DevOps du projet |
| Combien de fichiers Dockerfile dans le dépôt ? | 4 : `spring-boot/`, `django/`, `nginx/`, `nginx-azure/` |
| Combien de Nginx au total ? | 2 : un pour le routing local (P2), un pour le routing Azure (P6) |
| C'est quoi `alwaysdata` ? | Fichier posé par le prof, fallback AlwaysData, non utilisé chez nous |
