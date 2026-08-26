# Registre des écarts au cours (hors-TD)

> **But** : lister TOUT ce qui n'est pas littéralement dans les TDs. Chaque ligne ici = un endroit où le prof peut demander *« où tu sors ça ? on ne l'a pas vu en cours »*. On le complète au fil des leçons.
>
> Ce fichier est le **négatif** de `13-alignement-cours.md` (qui, lui, liste tout ce qui EST dans le cours, avec les pages). Ici on ne garde que les écarts.

## Légende

**Origine** :
- `CONSIGNE` = pas dans le TD mais **imposé par l'énoncé du projet** → défendable en pointant la consigne. Risque faible.
- `AJOUT` = **mon ajout** au-delà du TD → préparer une justification.
- `COMBI` = **combinaison de deux TDs** (rien de neuf, juste un assemblage) → défendable.
- `DISCORD-TD` = **les deux TDs se contredisent** → choix assumé.

**Gravité** :
- 🟢 trivial/standard → se justifie en une phrase, peu de risque.
- 🟡 à justifier → avoir une réponse propre prête.
- 🔴 sensible → vraiment hors-cours, **ne PAS le sortir de moi-même**, justification solide seulement si on me pousse.

---

## Section A — Écarts majeurs (repérés à l'audit des TDs)

| Écart | Fichier | Origine | Gravité | Quoi dire / consigne |
|---|---|---|---|---|
| Framework **Django** (`manage.py`/`runserver` — absent de TOUS les TDs) | `django/Dockerfile` | CONSIGNE | 🟢 | *« La consigne impose Django comme version B et spécifie `runserver 0.0.0.0:8000` + port 8000. »* — NB : Python + `pip` SONT vus (TD 06, TD 07), donc pas un écart |
| **Dockerfile nginx** (le TD 05 monte la conf en volume, pas via Dockerfile) | `nginx/Dockerfile` | CONSIGNE | 🟢 | *« La consigne P2 demande explicitement un Dockerfile nginx personnalisé. »* |
| **`proxy_ssl_server_name on`** (HTTPS sortant vers Azure) — `proxy_ssl_name` **supprimé le 2026-08-21** (c'était la valeur par défaut, donc une ligne morte) | `nginx-azure/nginx.conf` | AJOUT | 🟡 | *« Le TD 05 p.4 dit lui-même que le reverse proxy peut être amélioré 'par l'ajout de la gestion des requêtes HTTPS' et renvoie à la doc. Azure mutualise ses apps derrière les mêmes IPs : sans le nom d'hôte dans le handshake, pas de certificat. »* |
| **Azure CLI dans le pipeline** (`az login`, `az webapp restart`) — le TD 07 déploie sur AlwaysData en SSH | `.gitlab-ci.yml` | CONSIGNE P5 (+ `az` du TD 08) | 🟢 | *« La consigne P5 demande de déployer sur Azure via le pipeline ; j'utilise `az` du TD 08. »* |
| **`docker login` + `docker build/push` vers l'ACR dans un job** | `.gitlab-ci.yml` | CONSIGNE P5 + COMBI (TD07 mécanique docker démon-hôte + TD08 ACR) | 🟢 | *« Demandé par la consigne P5 ; technique docker = démon hôte du TD 07 p.20-22, PAS dind. »* |
| **`PORT` au lieu de `WEBSITES_PORT`** (TD 08 dit PORT, l'exemple Terraform du TD 09 dit WEBSITES_PORT) | `terraform/main.tf` l.56, 82 | DISCORD-TD | 🟡 | *« J'ai suivi l'instruction explicite du TD 08 p.4 ('PORT et non WEBSITES_PORT'). Ça marche. »* |

---

## Section B — Écarts fins, fichier par fichier (rempli au fil des leçons)

### Leçon 1 — `spring-boot/Dockerfile`
| Écart | Origine | Gravité | Quoi dire |
|---|---|---|---|
| `-DskipTests` sur `mvn clean package` | AJOUT | 🟢 | *« Je saute les tests ici parce qu'ils tournent dans le pipeline CI (Partie 3) ; ça évite de les jouer deux fois et accélère le build de l'image. »* Techniquement c'est une pratique standard, mais le TD ne le montre pas. |
| Tag exact `eclipse-temurin:21-jre-alpine` (le TD dit juste "base sur eclipse-temurin" sans préciser la variante JRE/alpine) | AJOUT | 🟢 | *« La variante JRE Alpine, c'est l'esprit 'optimiser les ressources' de l'exercice 4 : le strict minimum pour exécuter. »* |

### Leçon 2 — `django/Dockerfile` — ⚠️ CORRIGÉ après vérif de TOUS les TDs
> Correction importante : Python + `pip` ne sont PAS hors-cours. Le **TD 06** enseigne un projet Python (venv, pip, p.20-24), le **TD 07** a un job CI image `python:3.8` + `pip install` (p.13), le **TD 04** montre un `.dockerignore` Python (p.4-5). Seul **Django** (le framework) est absent des TDs — mais imposé par la consigne, qui spécifie même le lancement exact.

| Écart | Origine | Gravité | Quoi dire |
|---|---|---|---|
| `python:3.12-alpine` + `pip install` | **VU EN COURS** (TD 06 p.21 : pip/venv ; TD 07 p.13 : job CI `python:3.8` + `pip install`) | 🟢 | *« Python et pip sont vus en TD 06 et TD 07. »* — en réalité PAS un écart |
| Framework **Django** (`manage.py`, structure) | CONSIGNE | 🟢 | *« La consigne impose Django comme version B. »* |
| `CMD ... runserver 0.0.0.0:8000` + `EXPOSE 8000` | **CONSIGNE (littéral)** | 🟢 | *« La consigne spécifie exactement `python manage.py runserver 0.0.0.0:8000` et le port 8000. »* |
| `--no-cache-dir` | AJOUT (mais pip est en cours) | 🟢 | *« Pour ne pas garder le cache pip dans l'image, l'alléger. »* |
| ~~`RUN makemigrations && migrate` au build~~ → **résolu le 2026-08-21** : `makemigrations` retiré, il ne reste que `migrate` | AJOUT | 🟢 | *« `makemigrations` génère des fichiers de migration à partir des modèles ; mon projet n'en définit aucun. Il ne reste que `migrate`, qui crée les tables des apps Django intégrées. »* |

### Leçon 3 — `docker-compose.yml`
> **Rien de notable hors-TD** : `services`, `build`, `ports`, `depends_on`, `networks` sont tous couverts par le TD 04. Seuls détails cosmétiques ci-dessous.

| Écart | Origine | Gravité | Quoi dire |
|---|---|---|---|
| `container_name` explicite + nom `ab-network` choisis par moi | AJOUT cosmétique | 🟢 | *« Noms fixes pour la lisibilité ; sans impact technique. »* |
| (calibration) formulation exacte de `depends_on`/`bridge` dans TD 04 | — | — | TD 04 couvre ces concepts (confirmé) ; ouvrir le PDF seulement si besoin d'une citation mot pour mot |

### Leçon 4 — `nginx/nginx.conf` + `nginx/Dockerfile`
| Écart | Origine | Gravité | Quoi dire |
|---|---|---|---|
| **Dockerfile nginx** (TD 05 monte la conf en volume, pas via Dockerfile) | CONSIGNE | 🟢 | *« La consigne P2 exige un Dockerfile nginx personnalisé. »* |
| Mot **"round-robin"** (montré mais pas nommé dans TD 05 p.9 ; présent dans mon commentaire de code) | AJOUT vocab | 🟢 | *« C'est le comportement par défaut de l'upstream — alterne entre les serveurs. »* (ou dire juste "alterne") |
| Contraste **trailing slash** avec/sans (TD 05 p.4 parle de l'URL conservée, mais pas le contraste exact) | AJOUT compréhension | 🟢 | bien maîtriser le slash → `/test` devient `/` ; le TD touche au sujet p.4 |
| Noms choisis : upstream `apps-ab` | cosmétique (mais `apps_ab` cassait → RFC underscore) | 🟢 | anecdote du 400 Bad Request à raconter |

### Leçon 5 — `.gitlab-ci.yml` — ⚠️ RÉÉCRIT le 2026-08-21
> Pipeline refait après la remarque du prof (« le build fait la même chose, tu l'écrases »). Il est passé de 8 à 5 jobs et il est **plus aligné qu'avant** : `build-spring` est désormais quasi mot pour mot l'exemple du TD 07 p.12, et le cache Maven est celui du TD 07 p.13.

| Point | Origine | Gravité | Quoi dire |
|---|---|---|---|
| `artifacts: paths: - spring-boot/target/` + `expire_in: 1h` | **TD 07 p.12 — quasi verbatim** (le TD montre `mvn compile` + `artifacts: paths: - target/` + `expire_in: 1h`) | 🟢 | *« C'est l'exemple du TD 07 sur les artifacts, appliqué à mon projet. »* |
| `cache: paths: - .m2/repository/` + `-Dmaven.repo.local=$CI_PROJECT_DIR/.m2/repository` | **TD 07 p.13 — verbatim** | 🟢 | *« La mise en cache du dépôt Maven, exactement comme dans le TD. »* |
| **`cache: key: maven` / `key: pip`** — le mot `key` n'apparaît **0 fois** dans le TD 07 | AJOUT | 🟡 | *« Sans clé distincte, les deux caches partagent la clé par défaut et s'écrasent mutuellement : le job Maven réécrirait le cache pip. Une clé par type de dépendance. »* (bonne nouvelle : c'est le même mot « écraser » que la remarque du prof) |
| **`rules:` au niveau du job** (le TD 07 p.16 ne le montre qu'au niveau `workflow:`) | AJOUT / extension | 🟢 | *« Le TD met `rules` sur `workflow`, ce qui bloquerait tout le pipeline hors `main`. Je le mets sur les jobs `deploy` et `update` pour que `build` et `test` tournent quand même sur les autres branches. »* |
| `PIP_CACHE_DIR: "$CI_PROJECT_DIR/.cache/pip"` | COMBI — TD 07 exercice G demande de cacher `~/.cache/pip`, TD 07 p.13 montre le même déplacement pour Maven | 🟢 | *« GitLab ne met en cache que ce qui est sous `$CI_PROJECT_DIR`. C'est exactement la raison du `-Dmaven.repo.local` du TD, transposée à pip. »* |
| `variables:` au niveau pipeline (`MAVEN_REPO`, `RESOURCE_GROUP`, ...) | TD 07 p.6-7 | 🟢 | *« Les variables de pipeline sont dans le TD ; les secrets, eux, sont en variables masquées côté GitLab. »* |
| `before_script` pour le `docker login` | TD 07 p.9 | 🟢 | vu en cours |
| Pas de job de build Django | raisonnement propre | 🟢 | *« Python est interprété, il n'y a rien à compiler ni à transmettre. Installer les deps là ferait doublon avec `test-django`, qui doit les installer pour les tests. »* |
| 1 seul job `push-images` et 1 seul `update-apps` (au lieu de 2+2) | choix assumé | 🟢 | *« Un seul runner enregistré : deux jobs par stage ne tourneraient pas en parallèle et referaient chacun le même `docker login` / `az login`. »* |
| `deploy` : `docker login`/`build`/`push` vers l'ACR | CONSIGNE P5 + COMBI (TD07 démon hôte + TD08 ACR) | 🟢 | *« Demandé par la consigne P5 ; technique docker = démon hôte du TD 07 p.20-22, PAS dind. »* |
| Technique **démon hôte** (`docker.sock`), `image: docker:latest` | TD 07 p.20-22 | 🟢 | **NE PAS dire dind** |
| `docker login --password "$ARM_CLIENT_SECRET"` (pas `--password-stdin`) | CONSIGNE (forme littérale) | 🟢 | *« forme donnée par la consigne ; le secret est une variable masquée »* |
| `update` : `az login --service-principal` + `az webapp restart` | CONSIGNE P5 + TD 08 (`az`) | 🟡 | *« Le TD 07 déployait sur AlwaysData en SSH ; la consigne P5 impose Azure, donc j'utilise `az` du TD 08. Le restart force l'App Service à re-tirer l'image `:latest`. »* |

### Leçon 6 — `terraform/*`
> Très aligné : le TD 09 montre quasi mot pour mot ce pattern (Managed Identity → AcrPull → web app), p.16-21. Quasi aucun écart.

| Point | Origine | Gravité | Quoi dire |
|---|---|---|---|
| `PORT` au lieu de `WEBSITES_PORT` (TD 08 dit PORT, exemple Terraform TD 09 dit WEBSITES_PORT) | DISCORD-TD | 🟡 | *« J'ai suivi l'instruction explicite du TD 08 p.4 ; ça marche. »* (cf. Section A) |
| `admin_enabled = true` sur l'ACR alors que j'auth en Managed Identity | (présent dans le TD 09 aussi) | 🟢 | *« Je ne m'en sers pas pour l'auth — c'est la Managed Identity qui pull. Pourrait être `false` pour durcir ; laissé comme le TD. »* |
| 2 web apps nommées `spring`/`django` (le TD 09 en a 1 nommée `app`) | cosmétique (scénario A/B) | 🟢 | *« 2 apps parce que mon scénario a 2 versions. »* |
| Tout le reste (providers 4.66.0, resource_group, ACR, service_plan B1, linux_web_app, user_assigned_identity, role_assignment AcrPull, container_registry_use_managed_identity, application_stack, variables/outputs) | TD 09 p.16-21 | 🟢 | vu en cours, quasi verbatim |

### Leçon 7 — `nginx-azure/*` — ⚠️ CORRIGÉ le 2026-08-21
> **La version précédente ne fonctionnait pas.** L'`upstream` pointait directement sur les deux hôtes Azure. Or `proxy_pass` vers un upstream groupé transmet le **nom du groupe** en en-tête `Host` (mesuré : `Host: apps-ab-azure`), et Azure App Service route ses applications d'après le `Host` → 404 sur chaque requête. Vérifié aussi sans les lignes SNI : **la version strictement TD 05 échouait pareil**, donc les lignes SNI n'étaient pas la cause.
>
> **Le correctif ne sort pas du cours.** Le TD 05 contient deux motifs distincts : le reverse proxy vers un hôte HTTPS externe (p.3, `proxy_pass https://he2b.be/`) et le load balancer `upstream` vers des conteneurs locaux en HTTP (p.9). L'ancienne conf mélangeait les deux. La nouvelle les **compose** : l'`upstream` fait le round-robin entre deux blocs `server` locaux, et chacun de ces blocs proxifie vers son hôte Azure écrit en clair — ce qui fait transmettre le bon `Host`.

| Point | Origine | Gravité | Quoi dire |
|---|---|---|---|
| `upstream` + deux `server` locaux + `proxy_pass` vers un hôte HTTPS écrit en clair | **TD 05 p.3 et p.9 — composition des deux motifs du TD** | 🟢 | *« Le TD montre le reverse proxy vers un hôte HTTPS externe p.3, et le round-robin par upstream p.9. Je combine les deux : l'upstream alterne entre deux serveurs locaux, chacun relayant vers son App Service. »* |
| **Pourquoi pas les hôtes Azure directement dans l'upstream** | diagnostic mesuré | 🟢 | *« Parce qu'un upstream groupé envoie le nom du groupe en `Host`, et Azure route par le `Host` : les deux requêtes arrivaient en `Host: apps-ab-azure` et Azure renvoyait 404. »* — **excellente réponse, elle montre un vrai diagnostic** |
| `proxy_ssl_server_name on` | AJOUT, mais TD 05 p.4 y renvoie explicitement | 🟡 | *« Le TD 05 p.4 dit que le reverse proxy peut être amélioré par la gestion des requêtes HTTPS et renvoie à la doc. Azure a besoin du nom d'hôte dans le handshake TLS pour choisir son certificat. »* |
| ~~`proxy_ssl_name $proxy_host`~~ | **supprimé** | 🟢 | *« Je l'ai retirée : c'est la valeur par défaut de nginx, la ligne ne servait à rien. »* |
| Dockerfile nginx (idem P2, volume dans le TD) | CONSIGNE P6 | 🟢 | *« La consigne P6 redemande un Dockerfile nginx perso. »* |
| ⚠️ **Reste à vérifier sur le vrai Azure** | — | — | Le correctif est validé contre un faux Azure reproduisant le routage par `Host`. **Tester `/test` après `terraform apply`** avant la défense. |
