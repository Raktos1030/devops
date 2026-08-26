# Alignement au cours — preuves par TD

> But de cette fiche : pour CHAQUE choix technique du projet, savoir répondre à la question silencieuse du prof *« ça vient d'où, on l'a vu en cours ? »*. Audit fait en relisant les TD 03, 04, 05, 07, 08, 09 en entier, avec les numéros de page.

3 catégories :
- **Bucket 1** — c'est dans le TD (je cite la page, le prof ne peut rien dire)
- **Bucket 2** — pas dans le TD mais **imposé par la consigne** (donc obligatoire, pas un caprice)
- **Bucket 3** — **mon apport perso** au-delà du cours (à présenter comme MA recherche, jamais comme "vu en cours")

---

## Bucket 1 — Solidement dans le cours

| Technique | TD + page | Preuve |
|---|---|---|
| **Multi-stage build** (`FROM ... AS build` + 2e `FROM` + `COPY --from=`) | **TD 03 p.9-10 (Ex.4)** + TD 04 p.5 | "La commande `FROM` possède une option `AS nom`... une deuxième commande `FROM`... `COPY --from=`". **C'était ma plus grosse crainte, c'est en fait explicitement enseigné.** |
| Image `alpine` | TD 03 p.3 / TD 04 p.5 | "Utilisez une image de base légère (`FROM ...-alpine`)" |
| `LABEL author=` | TD 03 p.7 | exemple `LABEL author="g12345"` (identique au mien) |
| `EXPOSE`, `WORKDIR`, `CMD` exec | TD 03 p.7-8 | `CMD ["java","-jar",...]` mot pour mot |
| `.dockerignore` | TD 04 p.4-5 (Ex.1) | "fonctionne comme un `.gitignore`" |
| compose : `build`, `container_name`, `ports`, `depends_on`, `networks` + `driver: bridge` | TD 04 p.10-12 | tous présents avec définitions |
| DNS interne Docker (service appelé par son nom) | TD 04 p.9 | `jdbc:mysql://mysql-container:3306/...` |
| nginx `upstream` + round-robin + `proxy_pass` + `location` + `listen 80` | TD 05 p.3-9 | `upstream spring-backend { server ...; }` + `proxy_pass http://spring-backend/` |
| pipeline : `stages`, jobs, parallélisme | TD 07 p.10-12 | "exécution séquentielle" des stages, "jobs du même stage en parallèle" |
| Runner = conteneur Docker, executor docker | TD 07 p.2-4 | `docker pull gitlab/gitlab-runner`, `--executor docker` |
| Montage `/var/run/docker.sock` | TD 07 p.3, 20-21 | technique "accès au démon hôte" |
| `services: docker:dind` = l'AUTRE technique du TD (que je n'utilise PAS) | **TD 07 p.22** | Le TD montre dind comme alternative ; mon pipeline utilise le **démon hôte** (ligne au-dessus, `docker.sock`), donc **pas de `services: docker:dind` dans mon `.gitlab-ci.yml`**. |
| `docker build` dans un job | TD 07 p.20, 22 | `docker build -t ... .` |
| Variables CI masked / protected | TD 07 p.6-7 | "Masked : cachée dans les logs" / "Protected : branches protégées" |
| `rules:` / `workflow:` / `$CI_COMMIT_TAG` | TD 07 p.15-16 | `workflow: rules: - if:` ; `only` marqué "deprecated" |
| App Service conteneur + ACR | TD 08 p.1, 3 | "option Linux container", "Configurez Azure Container Registry" |
| **Auth ACR par Managed Identity** | **TD 08 p.3** | "Créer une identité managée... sans stocker de secrets" + "Accordez à l'identité managée l'accès à ACR". **Admin credentials JAMAIS montrés.** |
| Azure for Students / régions | TD 08 p.2, 4 | "Azure for Students limite les régions... `listOfAllowedLocations`" |
| Terraform : `required_providers` azurerm **`4.66.0`**, `providers.tf`, `features {}` | TD 09 p.16 | version pinée **identique** à la mienne |
| `azurerm_resource_group`, `azurerm_container_registry` (`sku`, `admin_enabled`) | TD 09 p.16-20 | `admin_enabled = true` est dans le TD |
| `azurerm_service_plan` Linux B1 (pas l'ancien nom) | TD 09 p.17, 20 | `os_type="Linux"`, `sku_name="B1"` |
| `azurerm_linux_web_app` (pas `azurerm_app_service`) | TD 09 p.18, 20 | nom de ressource moderne, identique |
| **`azurerm_user_assigned_identity`** | **TD 09 p.16-17, 19** | "Crée une identité managée pour l'authentification" |
| **`azurerm_role_assignment` rôle `AcrPull`** | **TD 09 p.17, 20** | `role_definition_name = "AcrPull"` + `principal_id = ...identity.principal_id` **mot pour mot** |
| **`container_registry_use_managed_identity = true` + bloc `identity {}`** | **TD 09 p.20** | code complet identique au mien. **Ma 2e grosse crainte → c'est le TD qui l'impose.** |
| `application_stack` / `docker_image_name` / `docker_registry_url` | TD 09 p.20 | identique |
| `variables.tf` (`default`) + `outputs.tf` | TD 09 p.18-21 | présents |
| `terraform init/plan/apply/destroy/validate` | TD 09 p.4-7, 21 | toutes les commandes |

🎯 **À retenir** : *« Mon `main.tf` est quasiment le copier-coller du TD 09 page 20. La chaîne Managed Identity → AcrPull → web app qui pull l'image, c'est exactement le pattern du cours, pas une invention. »*

---

## Bucket 2 — Pas dans le TD, mais IMPOSÉ par la consigne

Ce ne sont pas des écarts de ma part : c'est l'énoncé qui me l'a demandé.

| Élément | Pourquoi pas "comme le TD" | Ma défense |
|---|---|---|
| **Framework Django** (`manage.py`, `runserver`) — absent de tous les TDs | Python + `pip` SONT vus (TD 06 enseigne un projet Python venv/pip ; TD 07 a un job CI `python:3.8`) ; seul Django est consigne-only | *« La consigne impose Django comme version B et spécifie même `python manage.py runserver 0.0.0.0:8000` + port 8000. Python et pip, eux, sont vus en TD 06 et 07. »* |
| **Dockerfile nginx** (`FROM nginx:alpine` + `COPY`) | TD 05 montre un **montage volume** (`-v .../nginx.conf:...:ro`), pas un Dockerfile | *« La consigne P2 dit explicitement "créer un Dockerfile Nginx personnalisé". La consigne prime sur la méthode volume du TD. »* |

🎯 **À retenir** : *« Quand ma méthode diffère du TD, c'est parce que la CONSIGNE me le demande — je peux pointer la ligne de l'énoncé. »*

---

## Bucket 3 — Mon apport perso (au-delà du cours)

⚠️ **Ne JAMAIS dire "comme vu en cours" sur ces 3 points.** Les présenter comme MON travail de recherche pour répondre au scénario.

### 1. 🔴 SNI + HTTPS sortant (P6) — le plus gros écart
`proxy_ssl_server_name on`, `proxy_ssl_name`, le concept SNI : **absents de TD 05 ET TD 08.**
- TD 05 p.4 m'y invite quand même : *"amélioré par la gestion des requêtes HTTPS. Consultez la documentation."*
- La consigne P6 me demande de router A/B sur Azure.

**Phrase à dire** :
> *« Le TD 05 ne couvrait que le proxy HTTP local et m'invitait à consulter la doc pour le HTTPS. Pour la P6 j'ai cherché : Azure App Service mutualise des milliers d'apps sur les mêmes IPs publiques, donc pendant le handshake TLS il faut indiquer le nom de domaine via le SNI, sinon Azure ne sait pas quel certificat présenter et la connexion échoue. D'où `proxy_ssl_server_name on`. C'est mon apport pour répondre à la consigne. »*

### 2. Azure CLI dans le pipeline (`az login`, `az webapp restart`)
TD 07 déploie sur **AlwaysData en SSH/scp**, pas Azure.

**Phrase à dire** :
> *« Le TD 07 déployait sur AlwaysData en SSH. J'ai étendu le concept CI au scénario Azure de synthèse : un job avec l'image azure-cli qui s'authentifie en Service Principal et restart les App Services. »*

### 3. `docker login` + `docker push` vers l'ACR dans un job
TD 07 fait `build` mais jamais `login`/`push` vers un registre.

**Phrase à dire** :
> *« C'est la combinaison de deux TDs : le pipeline du TD 07 + le push vers l'ACR du TD 08 (qui le faisait au Portal). J'ai mis le push ACR dans un job de pipeline pour automatiser. »*

---

## ⚠️ LE piège : `PORT` vs `WEBSITES_PORT`

Mon `terraform/main.tf` (lignes 56 et 82) utilise **`PORT = "8080"` / `"8000"`**. Les deux TDs se **contredisent** :

| Source | Recommande |
|---|---|
| **TD 08 p.4** | **`PORT`** — *"ajoutez une variable nommée `PORT` (et **non plus** `WEBSITES_PORT`)... sinon Azure tente le port 80"* |
| **TD 09 p.20** | `WEBSITES_PORT` dans l'exemple Terraform |

Je suis aligné sur TD 08, pas sur l'exemple Terraform du TD 09. **On ne change rien** (`PORT` a marché, les apps répondent).

🎯 **Réponse en or si on me cuisine** :
> *« J'ai remarqué que les deux TDs divergent : le TD 08 page 4 dit explicitement d'utiliser `PORT` et non `WEBSITES_PORT`, alors que l'exemple Terraform du TD 09 utilise encore `WEBSITES_PORT`. J'ai suivi l'instruction la plus explicite — celle du TD 08 — et ça fonctionne, mes apps répondent sur leurs URLs Azure. »*

→ Montrer que j'ai repéré une incohérence du cours et tranché avec un raisonnement = très bon point.

---

## Petits gotchas (questions vicieuses)

| Question possible | Réponse |
|---|---|
| *« `admin_enabled = true` sur l'ACR alors que tu auth en Managed Identity ? »* | *« C'est dans le TD 09 aussi. Je ne m'en sers pas pour l'auth — c'est la Managed Identity + AcrPull qui pull. On pourrait le passer à `false` pour durcir, je l'ai laissé comme dans le TD. »* |
| *« Pourquoi `makemigrations && migrate` au build du Dockerfile Django ? »* | *« Je bake la base SQLite dans l'image pour une démo autonome. Le TD le fait au runtime, c'est un choix pour ce projet. »* |
| *« `--no-cache-dir` ? »* | *« Pas littéralement dans le TD, mais le principe "nettoyer le cache pour alléger l'image" oui (TD 04 p.5). Ça évite de garder le cache pip dans l'image. »* |
| *« Le trailing slash de `proxy_pass http://apps-ab/` ? »* | (voir fiche P2) *« Avec le slash, Nginx remplace `/test` par `/`. Sans, le backend reçoit `/test` qu'il ne connaît pas → 404. »* Le TD 05 montre l'effet sur l'URL mais pas le contraste avec/sans slash, donc je dois bien maîtriser la nuance. |

---

## Synthèse en 3 chiffres (à se répéter avant d'entrer)

- **~85%** strictement couvert par les TDs (pages ci-dessus à l'appui)
- **~10%** imposé par la consigne (Django, Dockerfile nginx)
- **~5%** mon apport perso (SNI/P6, Azure dans le pipeline) — présenté comme TEL

🎯 **La seule chose à ne pas rater** : le phrasé sur le **SNI** (Bucket 3 point 1). Tout le reste, je peux pointer une page de TD ou une ligne de consigne.
