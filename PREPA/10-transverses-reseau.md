# Transverse — Réseau, ports, DNS

Comment les conteneurs et les ressources Azure se parlent entre eux. Question 9 du prof tape direct là-dessus (schéma de ports). C'est aussi le sujet des questions sur `depends_on` (Q4), le port Django (Q3), et l'utilisation du suffixe `-ESI` (Q12).

## Vue d'ensemble — les 3 niveaux de réseau

```
1. Réseau Docker local         ←  P1, P2 (docker-compose)
2. Réseau public Internet       ←  P4, P5 (Azure)
3. Combinaison des deux         ←  P6 (Nginx local qui appelle Azure)
```

## Niveau 1 — Le réseau Docker local

### Le bridge network `ab-network`

🔧 **Code** : `projet/docker-compose.yml`

```yaml
networks:
  ab-network:
    driver: bridge
```

C'est un **réseau virtuel isolé** créé par Docker au lancement de `docker-compose up`. Tous les conteneurs attachés (`networks: - ab-network`) peuvent se parler par leur nom de service.

### Le DNS interne de Docker

C'est ce qui fait que dans `nginx.conf` on a :
```nginx
upstream apps-ab {
    server spring-boot:8080;   # ← "spring-boot" est résolu par Docker
    server django:8000;        # ← idem pour "django"
}
```

Docker maintient un mini-DNS pour chaque réseau bridge. Quand un conteneur résout `spring-boot`, il obtient l'IP interne du conteneur Spring Boot (de l'ordre de `172.18.0.x`).

🎯 **À retenir** : *« Le DNS interne Docker me permet de référencer les services par leur nom (`spring-boot`, `django`) au lieu de hardcoder des IPs. Ces noms ne sont valables QUE depuis l'intérieur du réseau Docker. »*

### ⚠️ Pièges potentiels

**« Et si je n'avais pas le réseau partagé `ab-network`, ça marcherait ? »**
- *« Non. Docker Compose crée un réseau par défaut, MAIS si je le déclare explicitement et que je n'attache pas tous les services dessus, ceux qui ne sont pas dessus ne pourraient pas résoudre les autres par nom. Le réseau explicite + `networks: - ab-network` sur chaque service garantit que les 3 services se voient. »*

**« Depuis ma machine hôte, je peux faire `ping spring-boot` ? »**
- *« Non. Le DNS Docker n'est dispo QUE depuis l'intérieur des conteneurs. Depuis l'hôte, je dois passer par `localhost:8080` ou `localhost:80` (les ports mappés). »*

**« C'est quoi `driver: bridge` exactement ? »**
- *« Bridge c'est le driver réseau par défaut de Docker sur Linux/Mac/Windows. Il crée un switch virtuel auquel les conteneurs s'attachent. Alternatives : `host` (conteneur dans le réseau de l'hôte, pas d'isolation), `overlay` (multi-hôte pour Swarm), `none` (pas de réseau). Pour un projet single-host comme le nôtre, bridge est le choix standard. »*

## Niveau 1 bis — Les ports, EXPOSE vs ports:

Différence fondamentale qui pète aux examens (Question 2 du prof) :

| | `EXPOSE 8080` (Dockerfile) | `ports: - "8080:8080"` (compose) |
|---|---|---|
| Quoi | Documentation, métadonnée de l'image | Mapping réel entre hôte et conteneur |
| Effet réseau | **AUCUN** | Crée un mapping `iptables/NAT` |
| Visible depuis l'hôte ? | Non | Oui (`localhost:8080` marche) |
| Visible depuis autre conteneur même réseau ? | Oui (via DNS Docker) | Oui (via DNS Docker) |

🎯 **À retenir** : *« `EXPOSE` c'est PUREMENT documentaire — ça aide `docker inspect` et certains outils, mais ça n'ouvre RIEN. `ports:` c'est ce qui ouvre vraiment l'accès depuis ma machine hôte. »*

### La démo Question 2 du prof

*« Commente l'instruction `EXPOSE` de ton Dockerfile, rebuild, vois ce qui se passe »* :

```bash
# 1. Commenter EXPOSE 8080 dans spring-boot/Dockerfile

# 2. Rebuild
docker-compose build spring-boot

# 3. Relancer
docker-compose up -d

# 4. Tester
curl http://localhost:8080
# → marche TOUJOURS, parce que c'est le `ports: - "8080:8080"` du compose qui fait le mapping, pas le EXPOSE.
```

**Réponse à donner au prof** : *« EXPOSE est purement documentaire, c'est une métadonnée de l'image. Le vrai mapping est fait par le `ports:` du docker-compose qui crée un mapping iptables sur l'hôte. Donc l'app marche toujours. »*

## Le mapping de ports — tableau complet

État final du projet :

| Service | Port interne (dans le conteneur) | Port mappé sur l'hôte | Comment l'utilisateur y accède |
|---|---|---|---|
| Spring Boot | 8080 | 8080 | `http://localhost:8080` |
| Django | 8000 | 8000 | `http://localhost:8000` |
| Nginx (local) | 80 | 80 | `http://localhost:80/test` (round-robin A/B) |

🎯 **À retenir** : *« 3 ports : 8080 pour Spring direct, 8000 pour Django direct, 80 pour le Nginx qui fait l'A/B. Pour la démo principale du projet on tape sur :80/test. »*

## Niveau 2 — Le réseau public (Azure)

### Les URLs Azure

| Type | Format | Mon cas |
|---|---|---|
| ACR (registre d'images) | `<acr-name>.azurecr.io` | `acrabtesting66045.azurecr.io` |
| App Service Spring | `<app-name>.azurewebsites.net` | `app-spring-66045.azurewebsites.net` |
| App Service Django | `<app-name>.azurewebsites.net` | `app-django-66045.azurewebsites.net` |

🎯 **À retenir** : *« Azure App Service expose chaque app sous `<nom>.azurewebsites.net` automatiquement, en HTTPS uniquement. Pas de port à préciser : c'est du 443 implicite. »*

### Pourquoi HTTPS et seulement HTTPS ?

Azure App Service n'écoute QUE en HTTPS. C'est une décision plateforme. Si tu fais `curl http://app-spring-66045.azurewebsites.net`, Azure répond avec un redirect 301 vers `https://`. Conséquence : dans le Nginx-Azure (P6), il faut absolument `proxy_pass https://` et le port `:443` dans l'upstream.

### ⚠️ Pièges potentiels

**« Pourquoi le nom de l'ACR a pas de tiret comme les App Services ? »**
- *« Azure interdit les tirets et points dans les noms d'ACR. Le nom doit être alphanumérique, en minuscules, 5-50 chars. C'est pour ça que j'ai `acrabtesting66045` tout en un. Les App Services autorisent les tirets donc j'ai `app-spring-66045`. C'est dans la doc Azure. »*

**« Et tu peux changer le nom de l'ACR après création ? »**
- *« Non. C'est un nom global unique dans tout Azure (un peu comme un bucket S3). Pour le changer il faut détruire et recréer. Donc je le fixe dans `variables.tf` et c'est mon `acr_name`. »*

## Niveau 3 — Le mix Local + Azure (P6)

Le Nginx-Azure tourne en local sur ma machine, mais il **proxify vers Internet** (vers les URLs Azure publiques). C'est un cas intéressant : le conteneur ne fait pas partie du réseau Azure, il atteint Azure via Internet.

```
┌───────────────────────────────┐
│  Ma machine                   │
│                               │
│  ┌────────────────────┐       │       Internet
│  │ nginx-azure        │       │           │
│  │ localhost:80       │       │           ▼
│  │  /test             │ ── HTTPS ────►  Azure
│  │                    │       │       app-spring-66045.azurewebsites.net:443
│  │                    │       │       app-django-66045.azurewebsites.net:443
│  └────────────────────┘       │
│                               │
└───────────────────────────────┘
```

### SNI (Server Name Indication)

Vu en P6 mais essentiel à connaître : Azure mutualise des milliers d'apps sur les mêmes IPs publiques. Quand Nginx ouvre une connexion TLS vers `app-spring-66045.azurewebsites.net`, il DOIT envoyer le nom de domaine pendant le handshake TLS, sinon Azure ne sait pas quel certificat servir.

→ Dans `nginx-azure/nginx.conf` :
```nginx
proxy_ssl_server_name on;          # active l'envoi du SNI
proxy_ssl_name $proxy_host;        # nom à envoyer (= nom de l'upstream)
```

🎯 **À retenir** : *« Le SNI permet à plusieurs sites HTTPS de partager la même IP. Sans `proxy_ssl_server_name on`, Azure ne sait pas quoi me servir et la connexion échoue. C'est une extension TLS standard mais qui doit être activée explicitement côté client (Nginx). »*

## Comment le round-robin marche

Dans `nginx.conf`, l'upstream `apps-ab` liste 2 backends. Nginx, par défaut, alterne :

| Requête # | Backend choisi |
|---|---|
| 1 | spring-boot |
| 2 | django |
| 3 | spring-boot |
| 4 | django |
| ... | ... |

C'est le comportement par défaut, **rien de spécial à coder**.

### Variantes possibles (non utilisées chez nous)

```nginx
upstream apps-ab {
    server spring-boot:8080 weight=3;   # reçoit 3 reqs sur 4
    server django:8000 weight=1;        # reçoit 1 req sur 4
}
```

Ou :
```nginx
upstream apps-ab {
    ip_hash;                              # même client → toujours même backend (sticky)
    server spring-boot:8080;
    server django:8000;
}
```

🎯 **À retenir** : *« Round-robin par défaut, c'est du 50/50. Si je voulais pondérer (style 80/20) j'ajouterais `weight=`, et pour sticky session je mettrais `ip_hash`. Pour le projet on garde le défaut, ça suffit pour démontrer le concept A/B. »*

## ACR et le lien vers les App Services

🔧 **Code** : `projet/terraform/main.tf`

```hcl
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.id_app.principal_id
}
```

Cette ressource donne à la **Managed Identity** des App Services le droit de tirer des images depuis l'**ACR**. Sans elle, les App Services ne pourraient pas pull et tomberaient en erreur au démarrage.

Combinée à :
```hcl
container_registry_use_managed_identity = true
container_registry_managed_identity_client_id = azurerm_user_assigned_identity.id_app.client_id
```

dans la config webapp, ça suffit : pas besoin de mot de passe ACR transporté.

🎯 **À retenir** : *« Le lien ACR ↔ App Service passe par la Managed Identity avec le rôle AcrPull. Pas de credentials ACR à donner aux App Services. C'est l'approche zero-secret. »*

## Mini-récap réseau

| Question | Réponse |
|---|---|
| Comment Nginx résout `spring-boot` ? | Via le DNS interne du réseau Docker `ab-network` |
| Différence EXPOSE vs ports: ? | EXPOSE = doc (rien ne se passe), ports = mapping réel |
| Combien de ports utilisés en local ? | 3 : 80 (Nginx), 8080 (Spring), 8000 (Django) |
| Pourquoi Azure n'autorise que HTTPS ? | Décision plateforme, port 443 implicite |
| C'est quoi SNI ? | Server Name Indication, extension TLS qui permet à plusieurs sites HTTPS de partager la même IP |
| Pourquoi le nom de l'ACR n'a pas de tiret ? | Azure n'autorise que [a-z0-9] dans les noms d'ACR (globalement unique) |
| Comment marche le round-robin Nginx ? | Comportement par défaut de l'upstream, alterne entre les serveurs déclarés |
| L'App Service comment pull l'image de l'ACR ? | Via Managed Identity + rôle AcrPull, pas de mot de passe |
