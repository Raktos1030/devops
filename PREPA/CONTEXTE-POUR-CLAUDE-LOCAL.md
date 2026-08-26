# Contexte de reprise — session locale

> Rachid : ouvre Claude Code sur ton Mac et dis-lui simplement
> **« lis PREPA/CONTEXTE-POUR-CLAUDE-LOCAL.md et enchaîne »**.
> Tout ce qu'il faut savoir est ci-dessous.

## Qui, quoi, quand

- Étudiant ESI, matricule **66045**, cours **4DOP1DR** (DevOps).
- **Défense orale imminente.** Il part de zéro sur le contenu du cours et manque de temps.
- Objectif prioritaire : **comprendre**, pas produire du code. Aucune fonctionnalité à ajouter.
- Le projet est noté sur la capacité à **expliquer n'importe quelle ligne** des fichiers écrits par lui
  (Dockerfile, docker-compose, nginx.conf, .gitlab-ci.yml, terraform/*). Le code applicatif
  Spring Boot / Django vient de l'école et n'est pas à défendre.

## Où sont les choses

| Quoi | Où |
|---|---|
| Le projet noté | `https://git.esi-bru.be/2025-2026/4dop1dr/c112/4dop1-66045.git` — cloné sur le Mac |
| Les fiches de révision | ce dossier `PREPA/` (16 fiches markdown) |
| Le cours « depuis zéro » | `PREPA/cours-express.html` — 5 échelles de zoom, à ouvrir dans un navigateur |
| Les 13 questions du prof | `PREPA/XX-questions-defense.md` — le document le plus rentable |
| PDF du cours et 2 projets d'exemple | `/` et `projet/` du dépôt GitHub `Raktos1030/devops` |

## État établi du projet (vérifié, ne pas re-débattre)

- Dernier commit sur `main` : **`f7fa4a6`** « nettoyage et corrections ».
- **Le local fonctionne** : `docker compose up --build` lance les 3 conteneurs,
  `curl http://localhost/test` alterne bien SPRING BOOT / DJANGO.
- **La partie 6 fonctionne** : `nginx-azure` build en `--no-cache` et alterne correctement sur le port 8090.
- **Azure tourne et répond 200** sur les deux App Services
  (`app-spring-66045` et `app-django-66045`, RG `rg-abtesting-66045`).
- Le débat `PORT` vs `WEBSITES_PORT` est **clos** : `EXPOSE` dans les Dockerfile suffit à App Service
  quand `WEBSITES_PORT` est absent. `terraform/main.tf` n'a aucun défaut à corriger.

## Règles posées par lui — à respecter sans discuter

- **NE PAS détruire Azure** (`terraform destroy` interdit). Aucun runner GitLab n'est enregistré sur le Mac,
  donc le pipeline ne peut pas être relancé depuis là, donc l'ACR ne pourrait pas être re-rempli :
  la démo Azure serait perdue sans possibilité de la rétablir.
- **Ne modifier aucun fichier du dépôt noté** sans demande explicite de sa part.
- Pas de `terraform apply`, pas de commande `az` autre qu'en lecture, pas de commit, pas de tag.
- Il n'attend pas de propositions de tests ni d'initiatives : exécuter, rapporter, attendre.

## État des pipelines GitLab (diagnostiqué)

Pipeline **#19672** sur `main` (commit `f7fa4a68`) affiché « Running / stuck » :
- `push-images` (#70526) et `update-apps` (#70527) sont **passés au vert** il y a 4 jours →
  tout le pipeline avait réussi.
- Le rouge vient de **relances manuelles du seul job `build-spring`** (#70602 canceled,
  #70603 et #70768 failed), et la dernière (#70769) est en **Pending / stuck**.
- Cause du « stuck » : **aucun runner en ligne**. Le runner est un conteneur Docker enregistré
  sur son PC **Windows** (`docker start gitlab-runner`), pas sur le Mac. Ce n'est pas un problème de code.
- Pipeline **#19674** sur le tag `nginx-azure` : **vert**, même commit. C'est la preuve à montrer au prof.

Le log des jobs `build-spring` en échec n'a jamais pu être lu — **à faire en priorité en local**
si le pipeline doit repasser au vert.

## Écart connu entre les fiches et le vrai dépôt

Les fiches `PREPA/05` et `PREPA/07` décrivent 8 jobs sur 4 stages, avec des jobs de déploiement nommés
`push-spring` / `push-django` et `update-spring` / `update-django`.

**Mais les pipelines réels montrent `push-images` et `update-apps`.** Le `.gitlab-ci.yml` a donc
été remanié depuis la rédaction des fiches.

→ **Première action en local : lire le vrai `.gitlab-ci.yml` du dépôt**, compter les stages et les jobs,
et corriger `PREPA/cours-express.html` (section « Échelle 4 », fichier n°1) pour qu'il colle au fichier
que le prof va réellement ouvrir. C'est le fichier le plus interrogé de tout le projet.

## Ce qui a déjà été fait dans la session web

- Diagnostic complet du pipeline (ci-dessus).
- Rédaction de `PREPA/cours-express.html` : le projet expliqué depuis zéro en 5 niveaux de zoom —
  (1) ce qu'est un test A/B et ce qu'il a fait lui-même, (2) les 6 parties/tags, (3) les deux flux
  local et Azure, (4) les 6 fichiers clés expliqués ligne par ligne et **classés par probabilité
  d'être interrogés**, (5) les manipulations à savoir faire en direct.
- Explication du refus d'authentification GitHub (token requis depuis 2021, pas le mot de passe).

## Suite prévue

1. Lire le vrai `.gitlab-ci.yml` et réaligner le cours dessus.
2. Lui faire lire les échelles 1 à 3 de `cours-express.html`.
3. **Mock défense** : lui poser au hasard les 13 questions de `XX-questions-defense.md`,
   le laisser répondre, pointer les trous. C'est ce qu'il a demandé ensuite.
4. Si le temps le permet : répéter en direct les manipulations de l'échelle 5
   (changer un port, commenter `EXPOSE`, retirer `depends_on`).

## Ton

Il est stressé et pressé. Réponses courtes, concrètes, une étape à la fois, pas de digression.
Vulgariser sans condescendance : il ne connaît pas le vocabulaire, mais il comprend vite.
