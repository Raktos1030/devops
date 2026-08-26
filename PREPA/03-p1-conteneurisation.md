# Partie 1 — Conteneurisation

## Ce que dit la consigne

> Conteneuriser les deux applications (Spring Boot + Django), créer un `docker-compose.yml` qui lance les deux ensemble, livrer + tag `conteneurisation` avant le 15 mai 18h00.

## Ce qu'on a fait

- `spring-boot/Dockerfile` (multi-stage : Maven → JRE Alpine)
- `spring-boot/.dockerignore` (exclut artefacts Maven, wrapper, IDE files)
- `django/Dockerfile` (single-stage : python:3.12-alpine)
- `django/.dockerignore` (exclut cache Python, venv, sqlite local)
- `docker-compose.yml` (version initiale, 2 services indépendants)
- `.gitignore` (à la racine)
- `README.md`

Tag : **`conteneurisation`** (sur le commit `0a91fa3`)

## Décortique du `spring-boot/Dockerfile`

🔧 **Code** : `projet/spring-boot/Dockerfile`

```dockerfile
# Etape 1 : compilation et empaquetage avec Maven
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app

# Copie du pom.xml et des sources
COPY pom.xml .
COPY src ./src

# Empaquetage de l'application en un fichier .jar
# Les tests seront executes dans le pipeline CI (Partie 3),
# on les saute ici pour accelerer le build de l'image.
RUN mvn clean package -DskipTests

# Etape 2 : image finale legere avec uniquement la JRE
FROM eclipse-temurin:21-jre-alpine
LABEL author="66045"
WORKDIR /app

# Copie du jar depuis l'etape de build
COPY --from=build /app/target/*.jar app.jar

# Port utilise par Spring Boot
EXPOSE 8080

# Lancement de l'application
CMD ["java", "-jar", "/app/app.jar"]
```

### Ligne par ligne

| Ligne | Rôle | Ce que tu dois savoir dire |
|---|---|---|
| `FROM maven:3.9-eclipse-temurin-21 AS build` | Image de base avec Maven 3.9 + JDK 21 + nommée `build` pour multi-stage | « Première étape, on utilise une image qui a Maven et le JDK 21 pour pouvoir empaqueter le `.jar`. Le `AS build` nomme cette étape pour qu'on puisse y faire référence plus tard. » |
| `WORKDIR /app` | Définit le répertoire de travail à `/app` (créé si inexistant) | « WORKDIR définit le dossier de travail pour les commandes suivantes — évite de répéter `cd /app` partout. » |
| `COPY pom.xml .` | Copie le pom.xml local dans le WORKDIR du conteneur | « On copie le pom.xml qui décrit les dépendances Maven du projet. » |
| `COPY src ./src` | Copie le dossier `src` local dans `/app/src` | « Le code source Java va dans `src/` à l'intérieur du conteneur. » |
| `RUN mvn clean package -DskipTests` | Build le projet en sautant les tests | « Maven compile et package en `.jar`. On saute les tests parce qu'ils tourneront dans le pipeline CI, ce qui accélère le build de l'image. » |
| `FROM eclipse-temurin:21-jre-alpine` | Deuxième image, ne contient que la JRE 21 sur Alpine Linux | « Deuxième étape du multi-stage : image légère qui n'a que la JRE, pas Maven ni le JDK complet. Résultat : image finale 3x plus petite. » |
| `LABEL author="66045"` | Métadonnée auteur | « Métadonnée pour traçabilité, mon matricule comme auteur de l'image. » |
| `COPY --from=build /app/target/*.jar app.jar` | Copie le jar depuis l'étape `build` | « `--from=build` récupère le jar produit dans la 1ère étape sans embarquer Maven dans l'image finale. » |
| `EXPOSE 8080` | Documente le port utilisé | « EXPOSE c'est de la doc, ça n'ouvre pas le port en soi. Spring Boot tourne sur 8080 par défaut, on documente. » |
| `CMD ["java", "-jar", "/app/app.jar"]` | Commande de démarrage du conteneur | « CMD est lancé au démarrage du conteneur. Format exec (tableau JSON) plutôt que shell — évite la couche shell intermédiaire. » |

### 🎯 À retenir

*« C'est un multi-stage build : une étape qui empaquette le `.jar` avec Maven, puis une image finale qui contient juste la JRE et le jar. L'image finale fait ~200 Mo au lieu de ~800 Mo avec une image Maven complète. »*

### ⚠️ Pièges potentiels

**« Pourquoi `-DskipTests` ? »**
- *« Les tests sont déjà couverts par le pipeline CI dans le job `test-spring` (mvn test). Les ré-exécuter dans le Dockerfile alourdirait le build de l'image. C'est aussi pour ça que la consigne demande des images optimisées. »*

**« Pourquoi `eclipse-temurin` et pas `openjdk` ? »**
- *« Eclipse Temurin c'est la JVM Open Source supportée par la fondation Eclipse, c'est l'image officielle recommandée. C'est aussi ce que le TD 03 utilise (`eclipse-temurin` exercice 2). »*

**« C'est quoi `alpine` ? »**
- *« Alpine Linux, une distribution Linux ultra minimaliste (~5 Mo). Permet de réduire drastiquement la taille des images Docker. Utilisée dans tous les TDs (TD 03, TD 04 exo « alpine »). »*

**« Pourquoi EXPOSE 8080 ? À quoi ça sert vraiment ? »**
- *« EXPOSE est purement déclaratif, c'est une métadonnée pour les outils. Ça n'ouvre PAS le port. Pour vraiment exposer un port il faut le `-p 8080:8080` au `docker run` ou le `ports:` dans `docker-compose.yml`. »*

**« Si je commente EXPOSE 8080, est-ce que ça change quelque chose ? »** (Question 2 du prof)
- *« Non, l'application continue de fonctionner exactement pareil parce que EXPOSE n'ouvre pas le port côté hôte. C'est uniquement le mapping `-p 8080:8080` (ou `ports:` dans compose) qui rend l'app accessible depuis l'hôte. EXPOSE sert juste à documenter et aider les outils de scan d'image. »*

## Décortique du `django/Dockerfile`

🔧 **Code** : `projet/django/Dockerfile`

```dockerfile
# Image de base Python legere
FROM python:3.12-alpine
LABEL author="66045"

WORKDIR /app

# Copie du fichier des dependances et installation
# --no-cache-dir evite de stocker le cache de pip dans l'image
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copie du code source de l'application
COPY . .

# Preparation de la base de donnees : generation et application des migrations
RUN python manage.py makemigrations && python manage.py migrate

# Port utilise par le serveur de developpement Django
EXPOSE 8000

# Lancement du serveur Django, accessible depuis l'exterieur du conteneur
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
```

### Ligne par ligne

| Ligne | Ce que tu dois dire |
|---|---|
| `FROM python:3.12-alpine` | « Image officielle Python 3.12 sur Alpine Linux pour rester léger. » |
| `COPY requirements.txt .` puis `RUN pip install...` | « On copie d'abord juste le `requirements.txt` et on installe les deps, AVANT de copier le code. Comme ça, si seul le code change, la couche pip install est en cache → build plus rapide. C'est de l'optimisation Docker layer caching. » |
| `--no-cache-dir` | « Pip garde par défaut un cache des wheels téléchargés dans `~/.cache/pip`. Dans une image Docker on n'en a pas besoin (on installe une fois), donc `--no-cache-dir` évite de gonfler l'image avec ce cache inutile. » |
| `COPY . .` | « On copie tout le code de l'app. » |
| `RUN python manage.py makemigrations && migrate` | « Migrations Django exécutées au build pour que la base SQLite soit déjà initialisée dans l'image. » |
| `CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]` | « On lance le serveur de dev Django sur `0.0.0.0:8000`. Le `0.0.0.0` est crucial : si on mettait `localhost` ou rien, le serveur n'écouterait que sur l'interface localhost du conteneur, donc inaccessible depuis l'extérieur. » |

### 🎯 À retenir

*« Image Python alpine, on installe d'abord les deps via `requirements.txt` (pour profiter du cache Docker), puis on copie le code, on fait les migrations, et on lance `runserver 0.0.0.0:8000`. »*

### ⚠️ Pièges potentiels

**« Pourquoi `0.0.0.0:8000` et pas juste `8000` ? »**
- *« Si on ne précise pas, Django écoute par défaut sur 127.0.0.1, qui est l'interface localhost interne du conteneur — donc inaccessible depuis l'extérieur même avec un port mapping. `0.0.0.0` veut dire "écoute sur toutes les interfaces" — ça inclut l'interface réseau virtuelle Docker qui relie le conteneur à l'hôte. »*

**« `manage.py runserver` c'est un serveur de prod ? »**
- *« Non, c'est le serveur de développement Django. Pour un vrai déploiement on utiliserait `gunicorn` ou `uwsgi`. Mais comme la consigne dit explicitement que les apps sont volontairement simples pour se concentrer sur le DevOps, on s'en contente. »*

## Décortique du `docker-compose.yml` (version P1)

🔧 **Code** : `projet/docker-compose.yml` (état au commit `0a91fa3`)

```yaml
services:
  spring-boot:
    build: ./spring-boot
    container_name: app-spring-boot
    ports:
      - "8080:8080"

  django:
    build: ./django
    container_name: app-django
    ports:
      - "8000:8000"
```

### Ligne par ligne

| Bloc | Rôle |
|---|---|
| `services:` | Déclare les conteneurs à orchestrer |
| `build: ./spring-boot` | Build l'image depuis le Dockerfile du dossier `spring-boot/` |
| `container_name: app-spring-boot` | Nom personnalisé du conteneur (sinon Docker en génère un aléatoire) |
| `ports: - "8080:8080"` | Map le port 8080 de l'hôte vers le port 8080 du conteneur |

### 🎯 À retenir

*« Compose initial très simple : deux services, chacun expose son port. Pas de réseau partagé pour l'instant, parce que Nginx (qui aura besoin du réseau pour résoudre `spring-boot` et `django` par nom) sera ajouté en Partie 2. »*

## .dockerignore — pourquoi c'est important

🔧 **Code** : `projet/spring-boot/.dockerignore` et `projet/django/.dockerignore`

```
# Maven artifacts
target/

# IDE files
.idea/, .vscode/, *.iml

# Git
.git/, .gitignore

# OS
.DS_Store, Thumbs.db
```

🎯 **À retenir** : *« Le `.dockerignore` exclut des fichiers du contexte envoyé au démon Docker pendant `docker build`. Évite de balancer des Mo inutiles (`target/`, `.git/`), évite aussi des fuites de secrets si on avait des fichiers sensibles. Concept symétrique au `.gitignore`. »*

### ⚠️ Piège potentiel (Question 13 du prof)

**« Supprime un de tes .dockerignore, reconstruis l'image, lance un conteneur et explore l'arborescence. »**
- Si on supprime `.dockerignore`, le build inclura `.git/`, `target/`, `.idea/`, etc. dans le contexte
- L'image finale pourrait grossir significativement
- Et surtout, certains fichiers (genre `application.properties` avec mot de passe en clair) finiraient dans l'image
- → c'est pour ça que le `.dockerignore` est important, même si « techniquement l'image marche encore sans »

## Mini-récap pour P1

| Question | Réponse |
|---|---|
| Combien d'étapes dans le Dockerfile Spring Boot ? | 2 (multi-stage) : build avec Maven, runtime avec JRE Alpine |
| Pourquoi multi-stage ? | Image finale légère (~200 Mo vs ~800 Mo) |
| Pourquoi `--no-cache-dir` dans pip ? | Évite de stocker le cache pip dans l'image (inutile) |
| Pourquoi `0.0.0.0` dans runserver ? | Écouter sur toutes les interfaces du conteneur, sinon inaccessible depuis l'hôte |
| À quoi sert EXPOSE ? | Documentation/métadonnée, n'ouvre pas le port. C'est `ports:` dans compose qui l'ouvre |
| Pourquoi `-DskipTests` ? | Tests faits dans le pipeline CI, accélère le build de l'image |
| Que se passe-t-il si je supprime .dockerignore ? | L'image inclut tout (`.git/`, `target/`...), grossit, risque fuites |
| Combien de services dans le compose initial ? | 2 (spring-boot et django), sans réseau partagé encore |
