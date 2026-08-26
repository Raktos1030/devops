# A/B testing - DEVOPS (4DOP1DR)

Rachid NAJJA - 66045

Deux versions de la meme application conteneurisees, routees par Nginx, et deployees sur Azure.

## Structure

- `spring-boot/` : version A, Spring Boot (Java 21, port 8080)
- `django/` : version B, Django (Python 3.12, port 8000)
- `nginx/` : reverse proxy local, route `/test` vers A ou B en round-robin
- `nginx-azure/` : meme role, mais vers les deux applications deployees sur Azure
- `terraform/` : infrastructure Azure (ACR, App Services, identite managee)
- `docker-compose.yml` : lance les 3 conteneurs en local
- `.gitlab-ci.yml` : pipeline CI/CD (compile, teste, construit et deploie les images)

## Lancer en local

```
docker compose up --build
```

- Version A : http://localhost:8080
- Version B : http://localhost:8000
- A/B test : http://localhost/test (alterne A/B a chaque requete)

Nginx repartit les requetes entre les deux serveurs de son bloc `upstream`.
La strategie par defaut est le round-robin, ce qui donne bien un partage 50/50.
Il faut donc recharger plusieurs fois `/test` pour voir la version changer.

Arret des conteneurs :

```
docker compose down
```

## Le pipeline CI/CD

Le pipeline est defini dans `.gitlab-ci.yml` et tourne sur le runner Docker
enregistre dans le depot. Ce runner est demarre avec un volume vers
`/var/run/docker.sock` : les jobs qui construisent des images utilisent donc le
demon Docker de la machine hote.

### Les quatre etapes

| Stage | Jobs | Role |
|---|---|---|
| `build` | `build-spring` | Compilation de l'application Spring Boot (partie 3) |
| `test` | `test-spring`, `test-django` | Tests unitaires des deux applications (partie 3) |
| `deploy` | `push-images` | Construction des images et envoi vers l'ACR (partie 5) |
| `update` | `update-apps` | Redemarrage des App Services pour prendre la nouvelle image |

Les stages s'executent en sequence : un stage ne demarre que si le precedent est
entierement passe.

### Optimisation du build et des tests

Chaque job GitLab s'execute dans un conteneur neuf : sans precaution, chaque
etape recompilerait et retelechargerait tout depuis zero. Deux mecanismes
l'evitent :

- **`artifacts`** : `build-spring` transmet son dossier `spring-boot/target/` au
  stage suivant. `test-spring` retrouve donc les classes deja compilees et ne
  recompile pas les sources.
- **`cache`** : le depot local Maven (`.m2/repository/`) et le cache de pip
  (`.cache/pip/`) sont conserves entre les jobs et entre les executions. Les
  dependances ne sont telechargees qu'une seule fois.

GitLab ne sauvegarde en cache que ce qui se trouve sous `$CI_PROJECT_DIR`. Or
Maven et pip ecrivent par defaut dans le repertoire personnel. Les variables
`MAVEN_REPO` et `PIP_CACHE_DIR` definies en haut du fichier redirigent ces deux
caches dans le projet, sans quoi la directive `cache:` n'aurait aucun effet.

A noter : les Dockerfile utilisent au contraire `pip install --no-cache-dir`.
L'objectif y est inverse, il s'agit de ne pas alourdir l'image finale.

### Declenchement

`build` et `test` tournent sur toutes les branches. Les stages `deploy` et
`update` sont limites a la branche `main` par une directive `rules` :

```yaml
rules:
  - if: '$CI_COMMIT_BRANCH == "main"'
```

Un commit sur une branche de travail est donc verifie, mais ne redeploie rien
sur Azure.

### Pourquoi ce nombre de jobs

La consigne laisse le nombre de jobs libre. Le decoupage retenu suit une regle
simple : aucun job ne doit refaire le travail d'un autre.

- **Le stage `build` ne contient qu'un seul job.** Java est compile, Python est
  interprete : il n'y a pas d'etape de compilation pour Django. Un job qui se
  contenterait d'y installer les dependances ferait double emploi avec
  `test-django`, qui doit de toute facon les installer pour lancer les tests.
- **`build-spring` et `test-spring` restent separes** parce que le premier
  transmet `target/` au second via `artifacts`. Sans cet echange les deux jobs
  compileraient les memes sources : `mvn test` passe par la phase `compile` du
  cycle de vie Maven et compile donc tout seul. Avec l'artifact, le job de test
  affiche `Nothing to compile - all classes are up to date`.
- **`deploy` et `update` ne comportent qu'un seul job chacun.** Le depot n'a
  qu'un seul runner : deux jobs dans un meme stage ne s'executeraient pas en
  parallele et referaient chacun le meme `docker login` ou le meme `az login`.

### Variables a definir dans GitLab

A renseigner dans *Settings > CI/CD > Variables* du projet, en **Masked** pour
les secrets :

| Variable | Contenu |
|---|---|
| `ACR_NAME` | Nom de l'Azure Container Registry (sans `.azurecr.io`) |
| `ARM_CLIENT_ID` | Identifiant du service principal Azure |
| `ARM_CLIENT_SECRET` | Secret du service principal |
| `ARM_TENANT_ID` | Identifiant du tenant Azure |

## Deployer sur Azure

L'infrastructure est creee manuellement, comme demande par la consigne : aucun
job du pipeline n'execute Terraform.

```
cd terraform
az login
terraform init
terraform apply
```

Terraform cree le groupe de ressources, l'Azure Container Registry, une identite
managee autorisee a tirer les images (role `AcrPull`), le plan App Service et
les deux applications web. Les URLs des applications sont affichees en sortie.

Une fois l'infrastructure en place, un push sur `main` declenche la construction
des images, leur envoi vers l'ACR et le redemarrage des deux App Services.

Pour ne pas consommer les credits Azure, detruire l'infrastructure apres usage :

```
terraform destroy
```

## Tags

Une etape du projet par tag : `conteneurisation`, `nginx`, `pipeline-ci`,
`infrastructure`, `deploiement`, `nginx-azure`.
