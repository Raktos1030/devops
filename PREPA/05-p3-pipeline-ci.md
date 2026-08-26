# Partie 3 — Pipeline CI

## Ce que dit la consigne

> Créer un pipeline CI qui :
> - Compile les applications
> - Exécute les tests unitaires
> Tag `pipeline-ci`.

## Ce qu'on a fait

- Enregistré un **GitLab Runner** sur ma machine (conteneur Docker, pas un .exe Windows)
- Écrit `.gitlab-ci.yml` à la racine avec 2 stages : `build` et `test`
- 4 jobs : `build-spring`, `build-django`, `test-spring`, `test-django`

Tag : **`pipeline-ci`** (sur le commit `73b2d4c`)
Commits : `8453efa` (jobs compile) + `73b2d4c` (jobs tests)

## L'architecture du pipeline (état P3)

```
push sur main
     │
     ▼
┌─────────────┐  ┌─────────────┐
│ build-spring│  │ build-django│   stage : build (parallèle)
└──────┬──────┘  └──────┬──────┘
       └────────┬───────┘
                ▼
┌─────────────┐  ┌─────────────┐
│ test-spring │  │ test-django │   stage : test (parallèle, après build)
└─────────────┘  └─────────────┘
```

## Décortique du `.gitlab-ci.yml` (état P3)

🔧 **Code** : `projet/.gitlab-ci.yml` au commit `73b2d4c`

```yaml
# Pipeline CI : compilation puis tests des deux applications.
# Le pipeline tourne sur le runner docker enregistre dans le depot.

stages:
  - build
  - test

# Compilation de l'application Spring Boot
build-spring:
  stage: build
  image: maven:3.9-eclipse-temurin-21
  script:
    - cd spring-boot
    - mvn compile

# Installation des dependances de l'application Django
build-django:
  stage: build
  image: python:3.12-alpine
  script:
    - cd django
    - pip install --no-cache-dir -r requirements.txt

# Tests unitaires de l'application Spring Boot
test-spring:
  stage: test
  image: maven:3.9-eclipse-temurin-21
  script:
    - cd spring-boot
    - mvn test

# Tests unitaires de l'application Django
test-django:
  stage: test
  image: python:3.12-alpine
  script:
    - cd django
    - pip install --no-cache-dir -r requirements.txt
    - python manage.py test
```

### Vocabulaire à maîtriser

| Mot | Définition |
|---|---|
| **Pipeline** | Processus automatisé qui exécute une série de jobs définis dans `.gitlab-ci.yml`. Déclenché sur événement (push, tag, merge request...). |
| **Stage** | Étape du pipeline. Les stages s'exécutent en séquence. |
| **Job** | Unité d'exécution dans un stage. Tous les jobs d'un même stage peuvent tourner en parallèle si plusieurs runners dispos. |
| **Runner** | Programme qui exécute les jobs. Tourne dans un conteneur Docker sur ma machine, enregistré auprès de GitLab via un token. |
| **Stage `build`** | Notre 1ère étape : compiler le code (mvn compile pour Spring, pip install pour Django) |
| **Stage `test`** | Notre 2e étape : tests unitaires (mvn test, python manage.py test) |

### 🎯 À retenir

*« Pipeline 4 jobs sur 2 stages. Build → Test, séquentiel entre stages, parallèle dans un stage. Chaque job utilise l'image Docker correspondant au langage (Maven pour Spring, Python alpine pour Django). »*

### Ligne par ligne du fichier

| Bloc | À dire |
|---|---|
| `stages: - build - test` | « Définit l'ordre des étapes. GitLab les exécute dans cet ordre. » |
| `build-spring:` | « Nom du job. Apparaît dans l'UI GitLab. » |
| `stage: build` | « Indique à quel stage appartient ce job. » |
| `image: maven:3.9-eclipse-temurin-21` | « Image Docker dans laquelle le job va tourner. Contient Maven 3.9 et JDK 21. Le runner va spawn un conteneur de cette image, y exécuter le `script`. » |
| `script:` | « Les commandes à exécuter dans le conteneur. » |
| `- cd spring-boot` | « On se place dans le dossier de l'app (le runner clone tout le repo à la racine). » |
| `- mvn compile` | « Compile le code Java. » |
| `pip install --no-cache-dir -r requirements.txt` | « Installe les deps Python du job Django. » |
| `mvn test` | « Lance les tests unitaires Spring Boot via Maven. » |
| `python manage.py test` | « Lance les tests Django (les classes héritant de `django.test.TestCase`). » |

## Le GitLab Runner — comment ça marche

Le runner c'est un conteneur Docker qui tourne en permanence sur ma machine, enregistré auprès de GitLab via un **registration token**. Il fait du long-polling sur GitLab : « t'as un job pour moi ? ».

Quand GitLab a un job, il le donne au runner. Le runner :
1. Spawn un nouveau conteneur Docker basé sur l'image du job (`image: maven:...`)
2. Clone le repo dedans (workspace)
3. Exécute le `script` dans ce conteneur
4. Renvoie les logs + le statut (succès/échec) à GitLab
5. Détruit le conteneur (chaque job tourne dans un conteneur frais → environnement reproductible)

🎯 **À retenir** : *« Mon runner est un conteneur Docker (image `gitlab/gitlab-runner:latest`) qui tourne en arrière-plan sur ma machine avec `--restart always`. Il s'authentifie à GitLab via un token de registration. Pour chaque job du pipeline, il spawn un conteneur frais basé sur l'image du job, y clone le repo, exécute le script, et détruit le conteneur. »*

### Commandes utilisées pour le setup runner (à connaître)

```bash
# 1. Pull l'image runner
docker pull gitlab/gitlab-runner:latest

# 2. Lancer le runner en background (long-running)
docker run -d --name gitlab-runner --restart always \
  -v /c/Users/Rachi/gitlab-runner/config:/etc/gitlab-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  gitlab/gitlab-runner:latest

# 3. Enregistrer le runner auprès de GitLab (1 fois)
docker run --rm -v /c/Users/Rachi/gitlab-runner/config:/etc/gitlab-runner \
  gitlab/gitlab-runner register \
  --non-interactive \
  --url "https://git.esi-bru.be" \
  --token "$RUNNER_TOKEN" \
  --executor "docker" \
  --docker-image "alpine:latest" \
  --description "docker-runner" \
  --docker-volumes "/var/run/docker.sock:/var/run/docker.sock"
```

### ⚠️ Pièges potentiels

**« À quoi sert le volume `/var/run/docker.sock:/var/run/docker.sock` ? »**
- *« Ça monte le socket Docker de la machine HÔTE dans le conteneur runner. Comme ça, quand un job du pipeline fait `docker build` ou `docker push`, le runner peut communiquer avec le démon Docker de mon PC, et builder/pusher des images via le Docker de l'hôte. Sans ça, il faudrait faire du Docker-in-Docker (DinD) qui est plus complexe. C'est la technique « accès au démon hôte » du TD 07 page 21. »*

**« Pourquoi le runner est un conteneur Docker et pas installé directement sur Windows ? »**
- *« Approche du TD 07 : on évite d'installer des deps sur l'hôte, on encapsule tout dans un conteneur Docker. Plus portable, plus propre. Si je change de machine je relance juste le conteneur. »*

**« Le runner peut faire tourner les jobs en parallèle ? »**
- *« Par défaut un seul à la fois (`concurrent = 1` dans la config). On peut augmenter pour qu'il en gère plusieurs en parallèle, mais ça consomme plus de ressources sur la machine. »*

## Le fait que chaque push trigger un pipeline (automatique)

GitLab détecte le `.gitlab-ci.yml` dans le repo. À chaque push (branche ou tag), il déclenche un pipeline automatiquement.

⚠️ **Subtilité importante** : un push de tag + un push de branche déclenchent **2 pipelines distincts** sur le même commit. C'est pour ça que tu vois souvent 2 pipelines verts d'affilée dans la liste GitLab. Comportement par défaut.

Pour limiter ça, on pourrait ajouter une règle :
```yaml
workflow:
  rules:
    - if: '$CI_COMMIT_BRANCH'  # ne tourne que sur push de branche
```

Mais on l'a pas fait dans le projet pour rester simple. Question 7 du prof peut tomber là-dessus.

## Variables prédéfinies utiles

GitLab CI injecte automatiquement des variables dans chaque job :
- `$CI_COMMIT_BRANCH` : nom de la branche du push
- `$CI_COMMIT_TAG` : nom du tag (vide si pas un push de tag)
- `$CI_COMMIT_SHA` : hash du commit
- `$CI_COMMIT_AUTHOR` : auteur du commit
- `$CI_PROJECT_DIR` : chemin du repo cloné dans le conteneur

On les utilise pas explicitement dans notre pipeline, mais le prof peut tester ta connaissance (Question 6 du prof).

## Mini-récap pour P3

| Question | Réponse |
|---|---|
| Combien de stages dans le pipeline P3 ? | 2 : `build` et `test` |
| Combien de jobs ? | 4 : build-spring, build-django, test-spring, test-django |
| Quelle image est utilisée pour les jobs Spring ? | `maven:3.9-eclipse-temurin-21` (Maven + JDK 21) |
| Quelle image pour les jobs Django ? | `python:3.12-alpine` |
| C'est quoi un GitLab runner ? | Programme qui exécute les jobs, chez nous un conteneur Docker enregistré auprès de GitLab |
| Pourquoi le volume `docker.sock` dans le runner ? | Pour que les jobs puissent faire `docker build`/`push` via le démon Docker hôte (P5) |
| Pourquoi 2 pipelines déclenchés sur un push avec tag ? | GitLab déclenche un pipeline par référence (branche + tag), comportement par défaut |
| Les jobs d'un même stage s'exécutent comment ? | En parallèle (si plusieurs runners) ; chez nous 1 runner donc séquentiel mais isolés |
| Comment skipper le pipeline sur les tags ? | Ajouter `workflow: rules: - if: '$CI_COMMIT_BRANCH'` (pas fait dans le projet) |
| Anecdote runner setup ? | Bug Git Bash : la spec `/var/run/docker.sock` a été convertie en chemin Windows + `:` → `;`, pipeline failed, j'ai corrigé manuellement `config.toml` du runner |
