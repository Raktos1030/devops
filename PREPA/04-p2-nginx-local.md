# Partie 2 — Nginx local A/B

## Ce que dit la consigne

> Mettre en place un conteneur Nginx qui redirige les utilisateurs entre les versions A (Spring Boot) et B (Django) sur la route `/test`. Utiliser la directive `upstream`. Mettre à jour le `docker-compose.yml`. Tag `nginx`.

## Ce qu'on a fait

- `nginx/Dockerfile` (image nginx:alpine + COPY de la conf custom)
- `nginx/nginx.conf` (upstream + location /test avec proxy_pass)
- `docker-compose.yml` mis à jour : ajout service nginx + réseau partagé `ab-network`

Tag : **`nginx`** (sur le commit `83453c0`)
Commits : `54bdeb4` (création nginx/), `83453c0` (intégration compose)

## Décortique du `nginx/Dockerfile`

🔧 **Code** : `projet/nginx/Dockerfile`

```dockerfile
# Image officielle Nginx, version alpine pour rester leger
FROM nginx:alpine
LABEL author="66045"

# Remplace la conf par defaut par notre conf personnalisee
COPY nginx.conf /etc/nginx/nginx.conf

# Port d'ecoute du serveur Nginx
EXPOSE 80
```

### Ligne par ligne

| Ligne | À dire |
|---|---|
| `FROM nginx:alpine` | « Image officielle Nginx sur Alpine Linux — légère. » |
| `COPY nginx.conf /etc/nginx/nginx.conf` | « On remplace le fichier de conf par défaut de Nginx par le nôtre. `/etc/nginx/nginx.conf` c'est le chemin standard de la conf Nginx dans l'image. » |
| `EXPOSE 80` | « Nginx écoute par défaut sur 80 (port HTTP standard). On documente. » |

### 🎯 À retenir

*« Dockerfile custom pour Nginx, juste un `FROM nginx:alpine` + un COPY de ma config. La consigne demande explicitement un Dockerfile personnalisé (au lieu de juste monter le fichier en volume). »*

### ⚠️ Pièges potentiels

**« Pourquoi un Dockerfile personnalisé et pas juste monter le fichier en volume comme dans le TD 05 ? »**
- *« La consigne de la Partie 2 demande explicitement "créer un Dockerfile Nginx personnalisé". Le pattern volume du TD 05 est valide en dev mais moins clean en prod : le Dockerfile encapsule la conf dans l'image, ce qui rend l'image autonome et déployable n'importe où sans dépendance à un fichier externe. »*

## Décortique du `nginx/nginx.conf`

🔧 **Code** : `projet/nginx/nginx.conf`

```nginx
events { }

http {
    # Regroupe les deux versions de l'application dans un upstream
    # Par defaut Nginx repartit les requetes en round-robin entre les serveurs
    # listes, ce qui donne un A/B testing 50/50.
    upstream apps-ab {
        server spring-boot:8080;
        server django:8000;
    }

    server {
        listen 80;

        # Toute requete sur /test est redirigee alternativement vers
        # la version A (Spring Boot) ou la version B (Django).
        # Le trailing slash sur proxy_pass remplace /test par / dans l'URL
        # transmise au backend, qui sert sa page d'accueil sur /.
        location /test {
            proxy_pass http://apps-ab/;
        }
    }
}
```

### Ligne par ligne

| Bloc / directive | À dire |
|---|---|
| `events { }` | « Bloc obligatoire de la conf Nginx, même vide. Il gère les paramètres connexion réseau (worker connections, etc.). On le laisse vide, défauts OK pour nous. » |
| `http { }` | « Bloc principal de la conf, contient toute la config HTTP. » |
| `upstream apps-ab { }` | « `upstream` déclare un groupe de serveurs backend. Le nom `apps-ab` est libre, c'est juste pour qu'on puisse y faire référence plus bas. » |
| `server spring-boot:8080;` | « Backend Spring Boot, identifié par le nom de service Docker `spring-boot` (résolu par le DNS interne du réseau Docker). » |
| `server django:8000;` | « Backend Django, idem. » |
| `server { listen 80; }` | « Déclare un serveur Nginx qui écoute sur le port 80. » |
| `location /test { proxy_pass http://apps-ab/; }` | « Route `/test` proxifiée vers l'upstream `apps-ab`. Le trailing slash après `apps-ab` est crucial. » |

### Le truc du **trailing slash** dans `proxy_pass`

C'est THE détail à connaître par cœur :

| `proxy_pass http://apps-ab/` (avec slash) | `proxy_pass http://apps-ab` (sans slash) |
|---|---|
| `/test` devient `/` côté backend | `/test` est transmis tel quel |
| Spring/Django ont une route `/` → ✅ marche | Spring/Django n'ont pas de route `/test` → ❌ 404 |

🎯 **À retenir** : *« Le slash à la fin de `proxy_pass` fait que Nginx remplace le préfixe matché par la location (`/test`) par juste `/`. Sans le slash, `/test` serait transmis tel quel aux backends, qui ne le reconnaissent pas. »*

### Le **round-robin** par défaut

Nginx ne fait rien de spécial : par défaut, quand on déclare plusieurs `server` dans un `upstream`, il alterne entre eux. Première requête → Spring, deuxième → Django, troisième → Spring, etc.

Pas de logique custom, pas de pourcentage, pas de cookie de session. **Simple round-robin**.

⚠️ **Piège potentiel** : *« comment tu garantis le 50/50 ? »* — *« C'est le comportement par défaut de l'upstream Nginx, j'ai rien codé en plus. Si on voulait du pondéré on aurait `server X weight=70; server Y weight=30;`, mais pour notre cas le défaut suffit. »*

### Le bug avec l'underscore (anecdote orale)

À la 1ère implémentation, j'avais nommé l'upstream `apps_ab` avec underscore. Premier test : 400 Bad Request.

Cause : quand Nginx proxifie vers l'upstream, il met le nom de l'upstream dans le header `Host` de la requête transmise au backend. Tomcat (utilisé par Spring Boot) applique strictement la RFC 952/1123 qui interdit les underscores dans les noms d'hôte → il refuse la requête.

Solution : renommer l'upstream avec un tiret au lieu d'un underscore (`apps-ab`). 2 caractères modifiés, ça marche.

🎯 **À retenir** : c'est une anecdote en or pour l'oral, montre que t'as débogué du vrai. *« Au début j'avais mis `apps_ab` avec underscore, mais Spring Tomcat refusait — RFC interdit l'underscore dans un nom d'hôte. J'ai renommé `apps-ab`, c'est passé. »*

## Décortique du `docker-compose.yml` (version P2)

🔧 **Code** : `projet/docker-compose.yml` (après commit `83453c0`)

```yaml
services:
  spring-boot:
    build: ./spring-boot
    container_name: app-spring-boot
    ports:
      - "8080:8080"
    networks:
      - ab-network

  django:
    build: ./django
    container_name: app-django
    ports:
      - "8000:8000"
    networks:
      - ab-network

  nginx:
    build: ./nginx
    container_name: nginx-ab
    ports:
      - "80:80"
    depends_on:
      - spring-boot
      - django
    networks:
      - ab-network

networks:
  ab-network:
    driver: bridge
```

### Ce qui a changé par rapport à la P1

- **Service `nginx`** ajouté (build depuis `./nginx`, expose port 80)
- **`depends_on`** sur nginx : il démarre APRÈS spring-boot et django
- **Bloc `networks:`** global déclarant `ab-network` en bridge
- **`networks: - ab-network`** sur chaque service pour les y attacher

### 🎯 À retenir

*« Compose mis à jour avec 3 services maintenant, tous sur un réseau Docker partagé `ab-network`. Sans ce réseau, Nginx ne pourrait pas résoudre les noms `spring-boot` et `django`. Avec, c'est le DNS interne de Docker qui s'en occupe automatiquement. »*

### ⚠️ Pièges potentiels

**« À quoi sert `depends_on` exactement ? »** (Question 4 du prof)
- *« `depends_on` garantit l'ORDRE de démarrage : Nginx démarrera après que spring-boot et django soient démarrés. MAIS attention, ça ne garantit PAS que les apps soient prêtes à répondre — juste que leur processus est lancé. Pour vraiment attendre qu'elles soient prêtes, il faudrait un `healthcheck` dans les services. C'est une nuance importante. »*

**« Si je supprime `depends_on`, qu'est-ce qui change ? »**
- *« Les services démarreraient potentiellement en parallèle. Si Nginx démarre AVANT les apps, ses premières requêtes upstream pourraient échouer parce que les backends ne sont pas encore là. En pratique Nginx réessaie, mais c'est moche. `depends_on` rend le démarrage prédictible. »*

**« C'est quoi `driver: bridge` ? »**
- *« `bridge` c'est le driver réseau Docker par défaut. Il crée un réseau virtuel isolé pour les conteneurs. Les conteneurs connectés au même réseau bridge peuvent se voir par leur nom de service, et l'extérieur n'y a accès QUE via les ports explicitement mappés avec `ports:`. »*

**« Pourquoi nginx sur port 80 et pas un autre ? »**
- *« 80 est le port HTTP standard, comme ça l'utilisateur tape juste `http://localhost/test` sans préciser de port. C'est plus propre. Si 80 était occupé par autre chose sur ma machine, j'aurais pu mettre 8888 ou 9090 — la consigne ne précise pas, j'ai choisi le standard. »*

## Schéma à dessiner si le prof le demande (Question 9 du prof)

```
   Machine hôte
   ─────────────
   localhost:80 ─────────────────────┐
   localhost:8080 ─────────────┐     │
   localhost:8000 ─────┐       │     │
                       │       │     │
   ┌───────────────────┼───────┼─────┼─────────┐
   │ Réseau Docker     │       │     │         │
   │ ab-network        │       │     │         │
   │                   ▼       ▼     ▼         │
   │  ┌────────┐   ┌─────────┐ ┌────────────┐  │
   │  │ django │   │ spring  │ │ nginx-ab   │  │
   │  │ :8000  │   │ :8080   │ │ :80        │  │
   │  └────────┘   └─────────┘ └──┬─────────┘  │
   │       ▲           ▲          │            │
   │       │           │          │            │
   │       └───────────┴── proxy_pass /test    │
   │           (round-robin via upstream)      │
   │                                           │
   └───────────────────────────────────────────┘
```

À l'oral si on te dit *« modifie le port de l'app Django de 8000 à 8050 »* (Question 3) :
1. Dans `docker-compose.yml` : `ports: - "8050:8050"` (ou garder `8050:8000` selon ce qui est attendu)
2. Dans `django/Dockerfile` : `CMD ["python", "manage.py", "runserver", "0.0.0.0:8050"]` ET `EXPOSE 8050`
3. Dans `nginx/nginx.conf` : `server django:8050;` au lieu de `:8000`

Si tu oublies un endroit, ça pète. Le prof teste ta capacité à faire le lien entre les fichiers.

## Mini-récap pour P2

| Question | Réponse |
|---|---|
| Quelle directive Nginx fait l'A/B testing ? | `upstream`, avec round-robin par défaut |
| Pourquoi le trailing slash dans `proxy_pass http://apps-ab/` ? | Pour que Nginx remplace `/test` par `/` côté backend, sinon backend reçoit `/test` qu'il ne connaît pas |
| Pourquoi `apps-ab` et pas `apps_ab` ? | Tomcat (Spring Boot) refuse les underscores dans le Host header (RFC 952/1123) |
| À quoi sert `depends_on` ? | Garantit l'ORDRE de démarrage, mais pas la disponibilité du service |
| Comment Nginx résout `spring-boot` et `django` ? | Via le DNS interne du réseau Docker partagé `ab-network` |
| `driver: bridge` ? | Driver réseau Docker par défaut, isolation entre conteneurs et hôte sauf ports mappés |
| Combien de services dans le compose après P2 ? | 3 : spring-boot, django, nginx |
| Sur quel port l'utilisateur accède à l'A/B testing ? | localhost:80/test |
