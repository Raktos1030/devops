# Mes phrases à dire au prof (script oral)

> **But** : les explications prêtes à dire, dans le vocabulaire du cours, fichier par fichier. Rempli au fil des leçons. À **relire à voix haute** la veille de la défense.
>
> Règle : tout ce qui est ici est calibré sur les TDs (mots du prof). Quand une ligne est un écart hors-TD, c'est marqué et renvoyé vers `14-hors-td-registre.md`.

---

## Leçon 1 — `spring-boot/Dockerfile` (version A)

### Le vocabulaire (mots exacts du TD 03)
- **Image** : *« un modèle qui contient tout ce dont une application a besoin pour s'exécuter : le code, les bibliothèques, les dépendances, les configurations. »* (TD p.2)
- **Conteneur** : *« une instance en cours d'exécution d'une image. »* (TD p.3)
- **Dockerfile** : *« un fichier texte qui contient une série d'instructions pour construire une image. »* (TD p.6)
- **Multi-stage** : le mot du TD (p.9), exercice 4. Sûr à 100%.

### Phrase d'intro (si le prof ouvre ce fichier)
> *« C'est le multi-stage build de l'exercice 4 du TD Docker : je compile dans une première image et je copie juste le résultat dans une image légère pour l'exécution. »*

### Si le prof pointe une ligne précise — ce que tu dis
| Ligne | Ta phrase |
|---|---|
| `FROM maven:3.9-eclipse-temurin-21 AS build` | *« Mon image de base pour la compilation : elle contient Maven et le JDK 21. Le `AS build` nomme cette étape pour pouvoir y faire référence plus bas. »* |
| `WORKDIR /app` | *« Définit le répertoire courant dans l'image ; il est créé s'il n'existe pas. Les instructions suivantes s'exécutent là. »* |
| `COPY pom.xml .` / `COPY src ./src` | *« COPY ajoute des fichiers locaux dans l'image : ici le pom.xml (les dépendances) et le code source. »* |
| `RUN mvn clean package -DskipTests` | *« RUN exécute une commande pendant la création de l'image : ici Maven empaquette l'app en `.jar`. Les tests, je les saute ici car ils tournent dans le pipeline (Partie 3). »* ⚠️ `-DskipTests` = hors-TD, voir registre |
| `FROM eclipse-temurin:21-jre-alpine` | *« Deuxième image, celle pour l'exécution : juste la JRE, le minimum pour faire tourner du Java. C'est elle qui devient l'image finale. »* |
| `LABEL author="66045"` | *« LABEL ajoute une métadonnée à l'image : ici mon matricule comme signature. »* |
| `COPY --from=build /app/target/*.jar app.jar` | *« Je copie le `.jar` produit dans l'étape `build` vers l'image finale. Le `--from=build` veut dire : prends-le dans la première image. »* |
| `EXPOSE 8080` | *« EXPOSE indique quel port le conteneur utilisera pour communiquer avec l'extérieur : ici 8080. »* |
| `CMD ["java", "-jar", "/app/app.jar"]` | *« CMD définit la commande lancée quand le conteneur démarre : ici exécuter le jar avec Java. »* |

### LA phrase clé — pourquoi deux `FROM` (à apprendre par cœur)
> *« Le premier `FROM` est une grosse image avec Maven et le JDK pour compiler mon application en `.jar`. Le deuxième `FROM` est une petite image avec juste la JRE pour l'exécuter. Je copie seulement le `.jar` du premier vers le deuxième avec `COPY --from=build`. Comme ça l'image finale ne contient que le nécessaire pour tourner, sans les outils de compilation : elle est plus légère. Ça optimise les ressources. »*

**Mémo 4 mots** : 1ère image = **compiler**, 2e image = **exécuter**.

---

## Leçon 2 — `django/Dockerfile` (version B)

### Concept clé : un seul `FROM` (pas de multi-stage)

### Phrase d'intro (si le prof ouvre ce fichier)
> *« Le Dockerfile Django est en une seule étape, contrairement à Spring, parce que Python est interprété : il n'y a pas de compilation, donc pas besoin d'image de build séparée. J'ai juste besoin de Python, des dépendances et du code. »*

### Lignes spécifiques à Python (les directives sont les mêmes qu'en Leçon 1)
| Ligne | Ta phrase |
|---|---|
| `FROM python:3.12-alpine` | *« Image de base Python légère, version Alpine. »* (✅ Python + pip sont vus en TD 06 et TD 07) |
| `RUN pip install --no-cache-dir -r requirements.txt` | *« pip installe les dépendances Python listées dans `requirements.txt`. `--no-cache-dir` évite de garder le cache de pip dans l'image, même esprit que le `apt-get clean` du TD. »* |
| `COPY . .` | *« Copie tout le code de l'app dans l'image, sauf ce qu'exclut le `.dockerignore`. »* |
| `RUN python manage.py makemigrations && python manage.py migrate` | *« Prépare la base SQLite : crée les tables au moment du build. »* (⚠️ hors-TD) |
| `EXPOSE 8000` | *« Port que le conteneur utilisera : 8000. »* |
| `CMD ["python","manage.py","runserver","0.0.0.0:8000"]` | *« Lance le serveur Django sur le port 8000. Le `0.0.0.0` = écouter sur toutes les interfaces, pour être joignable depuis l'extérieur du conteneur. »* |

### LA question de comparaison (à apprendre par cœur)
> *« Multi-stage pour Spring parce que Java est compilé : il faut Maven et le JDK pour produire le `.jar`, donc je sépare build et exécution. Un seul `FROM` pour Django parce que Python est interprété : pas de compilation, j'ai juste besoin de l'interpréteur, des dépendances et du code — un multi-stage n'apporterait rien. »*

**Mémo** : Java = compilé → multi-stage. Python = interprété → un seul FROM.

### Gotcha (seulement si on me pousse)
> *« runserver, c'est le serveur de développement de Django — mais c'est exactement ce que la consigne demande (`python manage.py runserver 0.0.0.0:8000`). En prod réelle on mettrait un serveur comme gunicorn. »*

## Leçon 3 — `docker-compose.yml` (TD 04)

### Phrase d'intro
> *« docker-compose orchestre mes 3 conteneurs d'un coup et les met sur un réseau commun pour qu'ils se parlent. »*

### Ligne par ligne
| Ligne | Ta phrase |
|---|---|
| `services:` | *« Je déclare mes 3 services = mes 3 conteneurs. »* |
| `build: ./spring-boot` | *« Construit l'image à partir du Dockerfile de ce dossier, au lieu d'une image toute faite. »* |
| `container_name: app-spring-boot` | *« Nom fixe et lisible pour le conteneur. »* |
| `ports: - "8080:8080"` | *« Le 8080 de ma machine pointe vers le 8080 du conteneur. »* (le TD dit "redirection de port" TD03 p.8 OU "mapping des ports" TD04 p.11 — les DEUX termes sont du cours) |
| `networks: - ab-network` | *« Rattache le service au réseau partagé. »* |
| `depends_on: - spring-boot - django` | *« nginx démarre après spring et django. »* |
| `networks: ab-network: driver: bridge` | *« Déclare le réseau, type bridge = réseau virtuel isolé ; permet aux conteneurs de se trouver par leur nom. »* |

### Les 2 points que le prof teste
**Réseau bridge + DNS interne :**
> *« Grâce au réseau partagé `ab-network`, nginx joint `spring-boot` et `django` par leur nom de service — c'est le DNS interne de Docker. Sans réseau commun, nginx ne pourrait pas les résoudre. »*

**`depends_on` (= Question 4 du prof) — la nuance clé :**
> *« `depends_on` garantit l'ORDRE de démarrage (nginx après spring et django), mais PAS que l'app soit prête à répondre — juste que son conteneur est lancé. Pour garantir la vraie disponibilité, il faudrait un `healthcheck`. »*
>
> ✅ **C'est du cours, mot pour mot** — TD 04 p.11 : *« depends_on : s'assurer qu'un service démarre avant un autre MAIS ne garantit pas qu'il soit totalement prêt à fonctionner »*, et liste `healthcheck` : *« vérifie si un service est prêt »*. Tu peux dire « comme dans le TD 04 ». (Notre compose à nous n'a pas de healthcheck → si on demande pourquoi : *« depends_on suffit pour l'ordre ; le healthcheck serait le raffinement pour la disponibilité, je sais l'ajouter, c'est dans le TD 04 ».*)

**Démarré ≠ prêt (la vraie différence)** : "démarré" = Docker a lancé le conteneur (le `java -jar` a commencé) ; "prêt" = Spring a fini de booter (~10-30 s plus tard) et répond sur 8080. Le **502 Bad Gateway** qu'on voit parfois au tout début = nginx qui tape sur Spring AVANT qu'il soit prêt. `depends_on` gère le "démarré" ; le `healthcheck` gérerait le "prêt".

**Mémo** : depends_on = ordre, PAS disponibilité.

### Pourquoi notre compose n'a PAS de healthcheck (+ comment l'ajouter si demandé)
**Pourquoi pas** : pas exigé par la consigne, et pas nécessaire chez nous — dans le TD 04 le healthcheck est sur MySQL parce que Spring DÉPEND de la base (sinon il plante) ; chez nous nginx tolère un 502 transitoire de quelques secondes au démarrage. Simplification assumée.

**Les 3 niveaux (honnête sur ce que ça apporte vraiment) :**
1. **`depends_on` simple seul** (ce qu'on a) → nginx démarre après que les conteneurs sont *lancés*, n'attend pas qu'ils *répondent* → 502 possible au démarrage.
2. **+ `healthcheck` sans `condition`** (= façon exemple TD 04) → ajoute juste un **indicateur de santé** visible dans `docker ps` (`(healthy)`). Dit si l'app répond mais **ne fait PAS attendre nginx** → 502 toujours possible. Apport = visibilité, pas blocage.
3. **+ `healthcheck` + `depends_on: condition: service_healthy`** → nginx attend vraiment l'état healthy → **plus de 502**. Mais combo **hors exemple TD 04**.

```yaml
# healthcheck façon TD 04, test adapté à une app web :
spring-boot:
  healthcheck:
    test: ["CMD", "wget", "--spider", "-q", "http://localhost:8080/"]
    retries: 10
    interval: 3s
    timeout: 30s
```
⚠️ `test` = outil présent dans l'image (`wget` ok sur Alpine, sinon `curl`).

**Honnêteté sur le TD** : son exemple = niveau 2, mais il écrit « vérifie que MySQL est prêt avant que l'app démarre » → optimiste, il faudrait le niveau 3 pour que ce soit vraiment vrai. À l'oral : NE corrige PAS le TD ; présente le healthcheck comme un check de disponibilité (rôle que le TD lui donne), et si tu veux montrer la profondeur : « pour forcer l'attente, on combine avec `condition: service_healthy` ».

**Live modif Q4 (le truc vraiment demandé)** : commenter/décommenter les 3 lignes `depends_on` du nginx → `docker compose up` → expliquer (ordre ≠ dispo). Trivial, à savoir faire sans réfléchir.

⚠️ Calibration : `depends_on` (liste simple) + `healthcheck` (clé séparée) = TD 04. Mais le combo `depends_on: condition: service_healthy` n'est PAS dans l'exemple du TD → à ne sortir que si à l'aise.

### 🔑 Concept transverse : mots-clés FIXES vs noms que JE choisis (sert pour Q3, Q12)
- **Mots-clés fixes** (le langage docker-compose, listés TD 04 p.11) : `services`, `build`, `container_name`, `ports`, `depends_on`, `networks`, `driver`, `healthcheck`, `image`, `environment`, `volumes`, `restart`… → jamais renommables, sinon erreur.
- **Valeurs fermées** : `driver: bridge` (parmi bridge/host/overlay/none) ; `condition: service_healthy` (parmi service_started/healthy/completed_successfully).
- **Noms que JE choisis** (renommables MAIS à répercuter partout) : noms de services (`spring-boot`, `django`, `nginx` → référencés dans `nginx.conf` upstream !), `ab-network` (sous chaque `networks:`), valeurs de `container_name`.
- **Réflexe** : si c'est dans la liste du TD 04 = mot-clé fixe. Si je l'ai inventé = je peux le changer, mais je cherche TOUTES ses références. (= exactement ce que testent Q3 renommer port, Q12 suffixe -ESI.)

## Leçon 4 — `nginx/nginx.conf` + `nginx/Dockerfile` (le cœur de la démo A/B, TD 05)

### Phrase d'intro
> *« C'est le reverse proxy qui fait l'A/B testing : toute requête sur `/test` part vers une de mes deux apps, en alternance. »*

### Dockerfile
| Ligne | Ta phrase |
|---|---|
| `FROM nginx:alpine` | *« Image officielle nginx, version Alpine légère. »* |
| `COPY nginx.conf /etc/nginx/nginx.conf` | *« Je remplace la conf par défaut par la mienne ; c'est l'emplacement standard de la conf dans l'image. »* |
| `EXPOSE 80` | *« nginx écoute sur 80 (HTTP standard). »* |
⚠️ Le TD 05 monte la conf en **volume**, pas via Dockerfile → *« la consigne P2 exige un Dockerfile nginx personnalisé »* (registre).

### nginx.conf
| Ligne | Ta phrase |
|---|---|
| `events { }` | *« Bloc obligatoire de toute conf nginx ; laissé vide, défauts OK. »* |
| `http { }` | *« Contient toute la config HTTP. »* |
| `upstream apps-ab { server spring-boot:8080; server django:8000; }` | *« `upstream` = un groupe de serveurs backend. `apps-ab` = nom que j'ai choisi. Mes 2 apps joignables par leur nom via le DNS interne du réseau Docker. »* |
| `listen 80` | *« nginx écoute sur 80. »* |
| `location /test { proxy_pass http://apps-ab/; }` | *« Toute requête `/test` part vers l'upstream. »* |

**Précisions clés** :
- `/test` est **défini ici** (bloc `location`), et sa valeur est **imposée par la consigne P2** (pas un nom inventé). Si on demande pourquoi /test → *« c'est la route demandée par la consigne »*.
- `location` = mot-clé fixe ; `/test` = la valeur (modifiable techniquement, ex. `/ab`, mais la consigne veut `/test`).
- nginx fait un **reverse proxy**, PAS une redirection HTTP : l'URL du navigateur reste `localhost/test`, nginx va chercher la page chez le backend et la renvoie. → dire « il **route / proxifie vers** », jamais « il redirige ».

### Round-robin (pourquoi ça alterne)
> *« Quand l'upstream a plusieurs `server`, nginx alterne par défaut : 1ère requête → Spring, 2e → Django, etc. C'est mon A/B, je n'ai rien codé de spécial. »*
⚠️ Le mot "round-robin" n'est PAS dans le TD 05 (le comportement y est montré p.9 sans être nommé) ; il est dans mon commentaire de code → je l'assume, ou je dis juste « nginx alterne entre les serveurs ».

### LE détail clé : le slash final de `proxy_pass`
> *« `proxy_pass http://apps-ab/` — le `/` final fait que nginx remplace `/test` par `/`, donc le backend reçoit `/` (sa page d'accueil). Sans le slash, le backend recevrait `/test` qu'il ne connaît pas → 404. C'est pour ça que `/test` marche alors que mes apps n'ont pas de route `/test`. »*

**Qui fait la transfo ?** nginx, **automatiquement** — je n'ai codé aucune règle "retire /test". Règle interne nginx : *si `proxy_pass` a un chemin (même `/`), nginx remplace la partie matchée par le `location` (`/test`) par ce chemin (`/`)*. `location /test` = ce qui est remplacé ; le chemin dans `proxy_pass` = par quoi. Pas de chemin dans proxy_pass = pas de substitution. **`/` = racine du BACKEND (spring-boot:8080 / django:8000), pas de localhost.**

**Synthèse : 2 décisions séparées par requête.** (1) le **chemin** = décidé par le slash → toujours `/`. (2) le **serveur:port** = décidé par le **round-robin** → alterne 8080 ↔ 8000. nginx envoie donc à `http://spring-boot:8080/` OU `http://django:8000/`, en alternance. Le `/` est constant, c'est le port qui change → c'est ça l'A/B qui alterne.

### Anecdote (bonus crédibilité)
> *« Au début l'upstream s'appelait `apps_ab` avec underscore → 400 Bad Request : nginx met le nom de l'upstream dans le header Host, et Tomcat refuse les underscores (RFC). Renommé `apps-ab` → réglé. »*

## Leçon 5 — `.gitlab-ci.yml` (le pipeline, P3 + P5, TD 07)

### Phrase d'intro
> *« Mon pipeline a 4 stages : `build` et `test` (Partie 3, la CI), puis `deploy` et `update` (Partie 5, le déploiement Azure). 8 jobs, 2 par stage (un Spring, un Django). »*

### Les 4 stages (séquentiels — TD 07 p.10)
`build` → `test` → `deploy` → `update`. Les stages s'exécutent en séquence ; les jobs d'un même stage en parallèle.

### Stage `build` (P3) — compiler / installer
| Job | Ta phrase |
|---|---|
| `build-spring` (image maven) `mvn compile` | *« Compile le code Java. »* |
| `build-django` (image python:3.12-alpine) `pip install -r requirements.txt` | *« Installe les dépendances Python. »* |

### Stage `test` (P3) — tests unitaires
| `test-spring` `mvn test` | *« Lance les tests unitaires Spring via Maven. »* |
| `test-django` `pip install` + `python manage.py test` | *« Lance les tests Django. »* |

### Stage `deploy` (P5) — build + push des images vers l'ACR
`push-spring` / `push-django`, `image: docker:latest` :
```yaml
- docker login "$ACR_NAME.azurecr.io" -u "$ARM_CLIENT_ID" --password "$ARM_CLIENT_SECRET"
- docker build -t "$ACR_NAME.azurecr.io/spring-boot:latest" ./spring-boot
- docker push "$ACR_NAME.azurecr.io/spring-boot:latest"
```
> *« Je me logge à l'ACR avec le Service Principal, je build l'image et je la push. »*
⚠️ **Technique = accès au démon HÔTE via `docker.sock` (monté dans le runner), PAS dind** (TD 07 p.20-22). `--password` = forme de la consigne.

### Stage `update` (P5) — redémarrer les App Services
`update-spring` / `update-django`, `image: mcr.microsoft.com/azure-cli:latest` :
```yaml
- az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
- az webapp restart --name app-spring-66045 --resource-group rg-abtesting-66045
```
> *« Je me connecte à Azure avec le Service Principal, puis je redémarre l'App Service pour qu'il re-pull la dernière image `:latest` depuis l'ACR. »*

### Le runner (TD 07 p.2-3)
> *« Mon runner est un conteneur Docker (`gitlab/gitlab-runner`) qui tourne sur ma machine, enregistré au projet via un token. Pour chaque job, il lance un conteneur frais basé sur l'image du job, exécute le script, renvoie le résultat. Il a été enregistré avec le volume `/var/run/docker.sock` pour que les jobs `deploy` puissent faire `docker build`/`push` via le démon Docker de l'hôte. »*
**Anecdote (TD 07 p.21)** : *« Au 1er pipeline, bug Git Bash : la spec `/var/run/docker.sock` a été convertie en chemin Windows + `:` → `;`, pipeline failed. J'ai corrigé `config.toml` à la main. C'est pile le piège "SOUS WINDOWS - GIT BASH ET //" du TD 07 p.21. »*

### Variables CI (TD 07 p.6-7)
`$ACR_NAME`, `$ARM_CLIENT_ID`, `$ARM_CLIENT_SECRET`, `$ARM_TENANT_ID` → définies dans GitLab **Settings > CI/CD > Variables**, en **Masked** (cachées dans les logs).

### D'où vient quoi (calibration)
- `build` + `test` (P3) = **100% TD 07** (stages, jobs, image, mvn/pip).
- `deploy` + `update` (P5) = **consigne** (P5 demande "le pipeline build les images + déploie sur Azure") + mécanique docker du TD 07 (démon hôte p.20-22) + `az` du TD 08.

### Questions du prof liées (toutes du TD 07)
- **Q6** (variable `DEPLOY_ENV` + condition) → `rules: - if: '$DEPLOY_ENV == "production"'` (variables p.6 + rules p.16).
- **Q7** (pipeline sur tag spécifique) → `workflow: rules: - if: '$CI_COMMIT_TAG == "presentation-2026"'` (TD 07 p.16, exercice sur tag `^v\d+\.\d+$`).
- **Q8** (partager une image entre jobs) → `artifacts` (TD 07 p.12-13) OU pousser vers un registre (notre cas : l'ACR).

## Leçon 6 — `terraform/*` (P4 infra Azure, TD 09)

### Phrase d'intro
> *« Mon Terraform décrit toute mon infra Azure en code : 4 fichiers (`providers`, `variables`, `main`, `outputs`), 7 ressources. Je le lance à la main — la consigne interdit de l'automatiser dans le pipeline. »*

### `providers.tf`
```hcl
terraform { required_providers { azurerm = { source = "hashicorp/azurerm", version = "4.66.0" } } }
provider "azurerm" { features {} }
```
> *« Je fixe le provider azurerm en version 4.66.0 (comme le TD 09 p.16). Le bloc `provider` est vide (`features {}`) sans `subscription_id` : Terraform lit les variables d'environnement `ARM_*` (ou ma session `az login`). »*

### `variables.tf` — 9 variables (toutes avec `default`)
`location` (francecentral), `resource_group_name`, `acr_name`, `identity_name`, `service_plan_name`, `spring_app_name`, `django_app_name`, `spring_image`, `django_image`. → *« Que des noms et la région, aucun secret dedans. »*

### `main.tf` — les 7 ressources (= Question 11 du prof)
| # | Ressource | Rôle (ta phrase) |
|---|---|---|
| 1 | `azurerm_resource_group` | *« Le conteneur logique qui regroupe tout ; permet de tout supprimer d'un coup. »* |
| 2 | `azurerm_user_assigned_identity` | *« La Managed Identity : l'identité Azure que mes App Services utilisent pour s'authentifier à l'ACR, sans secret. »* |
| 3 | `azurerm_container_registry` (sku Basic, admin_enabled true) | *« Stocke mes images Docker. »* |
| 4 | `azurerm_role_assignment` (`AcrPull`) | *« Donne à la Managed Identity le droit de pull depuis l'ACR. »* |
| 5 | `azurerm_service_plan` (Linux, B1) | *« La capacité CPU/RAM qui fait tourner les apps, mutualisée entre les 2. »* |
| 6-7 | `azurerm_linux_web_app` spring + django | *« Mes 2 apps en conteneur. Chacune : bloc `identity{UserAssigned}`, `container_registry_use_managed_identity=true`, `application_stack{docker_image_name}`, `app_settings{PORT}`. »* |

### `outputs.tf` — 3 outputs
`acr_login_server`, `spring_app_url`, `django_app_url` (URLs `https://...azurewebsites.net`).

### Le lien ACR ↔ App Service (zéro secret) — point fort
> *« Mes App Services pull les images depuis l'ACR sans mot de passe, grâce à la Managed Identity qui a le rôle AcrPull. C'est exactement le pattern du TD 09 (p.17 et p.20) : `container_registry_use_managed_identity = true` + le bloc `identity { type = "UserAssigned" }`. »*

### ⚠️ PORT vs WEBSITES_PORT (le piège, cf. fiche 13)
> *« Mon `app_settings` utilise `PORT`. Le TD 08 p.4 dit explicitement `PORT` (et non WEBSITES_PORT) ; l'exemple Terraform du TD 09 p.20 utilise encore `WEBSITES_PORT`. J'ai suivi l'instruction la plus explicite (TD 08), et ça marche. »*

### Commandes (TD 09)
`terraform init` (1×) → `plan` (vérifier) → `apply` (créer) → `destroy` (cleanup crédits).

### P4 = MANUEL (consigne)
> *« La consigne précise qu'aucun job du pipeline ne doit automatiser cette étape. Donc je lance `terraform apply` à la main. »*

### Questions du prof liées
- **Q10** (le prof déploie sur SON compte Azure) → *« Rien à changer dans mes `.tf`. Il fait `az login` sur son compte, crée un `terraform.tfvars` avec ses propres noms (acr_name, app names — uniques globalement sur Azure), puis `terraform init` + `apply`. Tout est externalisé dans les variables. »*
- **Q11** (lister les ressources + leur rôle) → les 7 ci-dessus.

## Leçon 7 — `nginx-azure/*` (P6, le 🔴 SNI)

### Phrase d'intro
> *« C'est un 2e nginx, séparé du premier. Même principe (router `/test` en A/B), mais il route vers mes apps déployées sur Azure (URLs publiques HTTPS) au lieu des conteneurs locaux. »*

### Le `nginx-azure/Dockerfile` (identique à celui de la P2)
`FROM nginx:alpine` + `LABEL` + `COPY nginx.conf` + `EXPOSE 80`.
> *« Identique au Dockerfile nginx de la P2. La consigne P6 redemande un Dockerfile nginx perso. La différence est dans le `nginx.conf`, pas le Dockerfile. »*

### Le `nginx.conf` — les différences avec la P2
```nginx
upstream apps-ab-azure {
    server app-spring-66045.azurewebsites.net:443;
    server app-django-66045.azurewebsites.net:443;
}
location /test {
    proxy_pass https://apps-ab-azure/;
    proxy_ssl_server_name on;
    proxy_ssl_name $proxy_host;
}
```
| | P2 (local) | P6 (Azure) |
|---|---|---|
| Cible | conteneurs locaux `spring-boot:8080` / `django:8000` | URLs publiques Azure `:443` |
| Protocole | `http://` | `https://` |
| Port | 8080 / 8000 | 443 (HTTPS standard) |
| SSL/SNI | rien | `proxy_ssl_server_name on` + `proxy_ssl_name` |

### Le SNI (🔴 TON apport — NE PAS présenter comme "vu en cours")
> *« Azure App Service mutualise des milliers d'apps sur les mêmes IPs publiques. Quand nginx ouvre une connexion HTTPS vers `app-spring-66045.azurewebsites.net`, il doit indiquer le nom de domaine pendant le handshake TLS — c'est le SNI (Server Name Indication) — sinon Azure ne sait pas quel certificat/app servir et la connexion échoue. D'où `proxy_ssl_server_name on` (active l'envoi du SNI) et `proxy_ssl_name $proxy_host` (le nom à envoyer). »*
⚠️ Le TD 05 ne couvre PAS le SNI ; il montre `proxy_pass https://` (p.3-4) et invite à consulter la doc pour le HTTPS. → présente le SNI comme **ton travail de recherche** pour répondre à la consigne P6.

### Pourquoi un 2e nginx séparé ?
> *« Cible différente : le nginx de la P2 route vers des conteneurs locaux en HTTP ; celui-ci route vers des URLs Azure publiques en HTTPS. La gestion SSL/SNI est différente, donc une conf séparée. »*

### Honnêteté si le prof creuse (le Host header)
> *« Avec un upstream multi-serveurs, le Host header par défaut est le nom de l'upstream, qu'Azure ne reconnaît pas comme un de ses apps. Mon A/B fonctionne en local (nginx P2) ; pour Azure l'idée est la même mais la gestion fine du Host header serait à affiner pour une vraie prod. Pour aller plus loin, Azure Front Door — mentionné dans la note de la consigne P6 — est le service natif pour ce genre de routing. »*

### Calibration
- Dockerfile + `upstream`/`proxy_pass`/`listen`/`location` = TD 05 (comme P2).
- `proxy_pass https://` + port 443 = HTTPS (TD 05 montre `https://` p.3-4).
- `proxy_ssl_server_name` / `proxy_ssl_name` / SNI = **🔴 hors-cours** (ton apport, justifié par la consigne P6 + l'invitation du TD 05 à consulter la doc).
