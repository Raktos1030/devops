# Partie 6 — Nginx Azure

C'est la dernière partie, et la plus courte.

## Ce que dit la consigne

> Mettre en place un **nouveau** conteneur Nginx qui redirige les utilisateurs entre les versions A (Spring Boot) et B (Django) **déployées sur Microsoft Azure**.
> - Créer un Dockerfile Nginx personnalisé.
> - Configurer Nginx pour que `/test` route vers les apps Azure.
> Tag `nginx-azure`.

## Ce qu'on a fait

Création du dossier `nginx-azure/` (séparé du `nginx/` de la P2) :
- `nginx-azure/Dockerfile`
- `nginx-azure/nginx.conf`

Tag : **`nginx-azure`** (sur le commit `cc9997a`)
Commit : `cc9997a`

## Différence entre `nginx/` et `nginx-azure/`

| `nginx/` (P2) | `nginx-azure/` (P6) |
|---|---|
| Route vers les conteneurs LOCAUX (`spring-boot:8080`, `django:8000`) | Route vers les URLs PUBLIQUES Azure (`app-spring-66045.azurewebsites.net`, etc.) |
| Connexion HTTP en intra-réseau Docker | Connexion HTTPS sur Internet |
| Pas de SNI / Host header magic | Doit gérer SNI parce que Azure mutualise plusieurs apps sur les mêmes IPs |
| Utilisé pour tester en local | Utilisé pour faire de l'A/B testing sur l'infra prod |

🎯 **À retenir** : *« Deux Nginx parce que deux usages différents. Le premier route vers des conteneurs locaux dans un réseau Docker, le second route vers des URLs publiques Azure en HTTPS. La différence principale c'est la gestion SSL/SNI. »*

## Décortique du `nginx-azure/Dockerfile`

🔧 **Code** : `projet/nginx-azure/Dockerfile`

```dockerfile
FROM nginx:alpine
LABEL author="66045"

COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 80
```

Identique à `nginx/Dockerfile` (P2). Pas grand chose à dire en plus.

🎯 **À retenir** : *« Dockerfile identique à celui de la Partie 2, c'est juste un `nginx:alpine` qui copie ma conf custom. La différence avec la P2 est dans le fichier `nginx.conf`, pas dans le Dockerfile. »*

## Décortique du `nginx-azure/nginx.conf`

🔧 **Code** : `projet/nginx-azure/nginx.conf`

```nginx
events { }

http {
    upstream apps-ab-azure {
        server app-spring-66045.azurewebsites.net:443;
        server app-django-66045.azurewebsites.net:443;
    }

    server {
        listen 80;

        location /test {
            proxy_pass https://apps-ab-azure/;
            proxy_ssl_server_name on;
            proxy_ssl_name $proxy_host;
        }
    }
}
```

### Ligne par ligne

| Ligne | À dire |
|---|---|
| `upstream apps-ab-azure { ... }` | « Upstream avec les 2 URLs Azure. Le port 443 (HTTPS standard) parce que Azure App Service expose en HTTPS uniquement. » |
| `server app-spring-66045.azurewebsites.net:443;` | « Backend Spring sur Azure. Le port doit être explicitement 443 pour HTTPS (pas 80 comme en P2). » |
| `proxy_pass https://apps-ab-azure/;` | « `https://` (et pas `http://` comme en P2), parce qu'on parle à Azure qui n'écoute pas en HTTP non chiffré. » |
| `proxy_ssl_server_name on;` | « Active SNI (Server Name Indication) sur la connexion TLS sortante. Indispensable pour Azure App Service qui mutualise plusieurs apps sur les mêmes IPs : sans SNI Azure ne sait pas vers quelle app router. » |
| `proxy_ssl_name $proxy_host;` | « Spécifie le nom à envoyer dans SNI : ici `$proxy_host` qui est résolu dynamiquement par Nginx. » |

### Le concept SNI — à savoir expliquer

**SNI = Server Name Indication.** C'est une extension du protocole TLS qui permet au CLIENT de dire au SERVEUR "je veux causer à tel domaine" pendant le handshake TLS.

Pourquoi c'est utile : un même serveur peut héberger plusieurs sites HTTPS différents (avec leurs propres certificats). Avant SNI, il fallait une IP par site (puisque le serveur ne savait pas avant le handshake quel cert présenter). Avec SNI, le serveur sait dès le hello quel cert utiliser → mutualisation possible.

Azure App Service fait massivement de la mutualisation : des milliers d'apps partagent les mêmes IPs publiques. Sans SNI dans la requête HTTPS sortante, Azure renvoie un certificat random et la connexion échoue.

🎯 **À retenir** : *« Le SNI c'est l'extension TLS qui permet de dire "je veux causer à tel domaine" pendant le handshake. Azure App Service en a besoin parce qu'il mutualise plusieurs apps sur les mêmes IPs. Sans `proxy_ssl_server_name on`, la connexion HTTPS depuis Nginx échouerait. »*

### ⚠️ Pièges potentiels

**« Si tu enlèves `proxy_ssl_server_name on`, ça marche encore ? »**
- *« Non. Nginx tenterait une connexion HTTPS sans SNI, Azure ne saurait pas quelle app cible et renverrait soit une erreur, soit un mauvais certificat → erreur SSL. C'est testable, vérifie en commentant la ligne et `docker-compose up`. »*

**« Pourquoi tu n'as pas mis ce Nginx-Azure aussi dans le docker-compose.yml ? »**
- *« Volontairement. Le `docker-compose.yml` orchestrait les services LOCAUX pour le développement (Spring, Django, Nginx local). Le `nginx-azure` est conceptuellement différent : il route vers des URLs Internet, pas vers des conteneurs locaux. On peut le builder et lancer indépendamment avec `docker build ./nginx-azure && docker run`, mais il n'a pas sa place dans le compose de dev. »*

**« Et le `Host` header pour Azure ? »**
- *« Question subtile. Quand Nginx proxy vers l'upstream avec plusieurs serveurs, le Host header par défaut est le nom de l'upstream (`apps-ab-azure`). Azure ne reconnaîtra pas ce Host comme étant un de ses apps → 404. Pour une vraie implémentation production, il faudrait soit un `proxy_set_header Host $upstream_host` (ce qui ne marche pas vraiment proprement avec upstream multi-server), soit un `split_clients` + `map` pour router avec un Host header dynamique par backend. Notre implémentation simple suit le TD 05 mais a cette limite en pratique. À l'oral, si on creuse, on peut le dire honnêtement : "l'A/B test fonctionne en local avec le Nginx P2 ; pour Azure, l'idée est la même mais la gestion du Host header serait à affiner pour une vraie prod". »*

**« Pourquoi t'as choisi de ne pas déployer le nginx-azure sur Azure ? »**
- *« La consigne demande de "mettre en place un nouveau conteneur Nginx" → ça veut dire le concevoir et le packager. Elle ne dit pas explicitement "le déployer sur Azure". On l'a donc créé en image Docker buildable mais pas inclus dans le pipeline ou le Terraform. Pour aller plus loin, on aurait pu : 1) ajouter un App Service dédié pour ce Nginx dans Terraform, 2) ou utiliser Azure Front Door (mentionné dans la note de la consigne) qui est le service Azure natif pour ce genre de routing. »*

## Mini-récap pour P6

| Question | Réponse |
|---|---|
| Pourquoi un nouveau Nginx au lieu de réutiliser celui de la P2 ? | Cible différente : URLs Azure publiques HTTPS vs conteneurs locaux HTTP |
| Pourquoi HTTPS et port 443 ? | Azure App Service n'écoute qu'en HTTPS, jamais en HTTP non chiffré |
| C'est quoi SNI ? | Server Name Indication, extension TLS qui dit au serveur quel domaine on cible avant le handshake. Essentiel pour la mutualisation d'apps sur les mêmes IPs (cas d'Azure App Service) |
| À quoi sert `proxy_ssl_server_name on` ? | Active l'envoi du SNI sur la connexion HTTPS sortante de Nginx vers les backends Azure |
| Pourquoi pas dans le docker-compose ? | Le compose est pour les services LOCAUX. Le nginx-azure route vers Internet, contexte différent |
| Le nginx-azure est-il déployé sur Azure ? | Non. Le projet ne le demande pas explicitement. Pour aller plus loin, on pourrait soit l'ajouter à Terraform, soit utiliser Azure Front Door (mentionné dans la consigne note de P6) |
| Quel est l'équivalent Azure natif de notre nginx-azure ? | Azure Front Door — service de routing / load balancing global mentionné dans la note de la consigne |
