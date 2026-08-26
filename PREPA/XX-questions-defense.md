# Les 13 questions du prof — réponses détaillées

> Source : `4DOP1DR_ Liste de questions _ poési.pdf` posté par le prof comme préparation à la défense orale.

C'est **LA section** la plus importante de la prépa. Le prof a explicitement dit que ces 13 questions sont des "types" — il peut piocher dedans ou s'en inspirer. À lire à voix haute la veille.

**Règle d'or** : avant de répondre, **toujours pointer le code concerné dans VS Code**. Le prof veut voir que tu sais OÙ chercher, pas juste que tu connais une théorie.

---

## Q1 — Expliquer une instruction précise

> *« Expliquez une instruction précise dans l'un de vos Dockerfiles, du gitlab-ci.yml ou de votre script Terraform. »*

C'est la question la plus fréquente : le prof pointe une ligne au pif et demande "ça fait quoi ?".

### Stratégie de réponse

1. **Lire à voix haute** la ligne et son contexte (ligne précédente / suivante).
2. **Nommer la directive** : « C'est un `FROM` », « C'est un `COPY --from=` », « C'est un `proxy_pass` ».
3. **Dire ce qu'elle fait techniquement**.
4. **Justifier le choix** : pourquoi cette instruction et pas une autre.

### Exemples préparés

**Cas A — `COPY --from=build /app/target/*.jar app.jar` (Dockerfile Spring)**
- *« C'est l'instruction `COPY` du multi-stage. `--from=build` veut dire "copie depuis le stage nommé `build`" (déclaré en haut avec `FROM maven:... AS build`). On copie le `.jar` produit par Maven dans le stage 1 vers le stage 2 qui est juste un JRE Alpine. Comme ça l'image finale ne contient pas Maven, juste le JRE et le JAR. Image finale ~150 MB au lieu de ~600 MB avec Maven dedans. »*

**Cas B — `proxy_pass http://apps-ab/` (nginx.conf)**
- *« `proxy_pass` envoie la requête vers l'upstream `apps-ab` qui contient mes 2 backends. Le slash final est crucial : il fait que Nginx remplace `/test` par juste `/` quand il forward au backend. Sans le slash, Spring/Django recevraient `/test` qu'ils ne connaissent pas → 404. »*

**Cas C — `resource "azurerm_role_assignment" "acr_pull"` (main.tf)**
- *« C'est une ressource Terraform qui donne à ma Managed Identity le rôle `AcrPull` sur mon Container Registry. Sans ça, mes App Services ne pourraient pas pull les images depuis l'ACR au démarrage. C'est l'instruction qui matérialise la confiance ACR → App Service via la Managed Identity, sans qu'il y ait de credentials à transporter. »*

**Cas D — `image: maven:3.9-eclipse-temurin-21` (.gitlab-ci.yml)**
- *« C'est l'image Docker dans laquelle le job va tourner. Maven 3.9 avec un JDK 21 Eclipse Temurin (= openJDK). Le runner GitLab va spawner un conteneur de cette image, y cloner mon repo, et exécuter le `script:` à l'intérieur. À la fin il détruit le conteneur. C'est ce qui me garantit un environnement reproductible : à chaque pipeline, c'est exactement la même version de Maven et de Java. »*

🎯 **À retenir** : *« Pour chaque ligne, dire : 1) qu'est-ce que c'est, 2) ce que ça fait, 3) pourquoi je l'ai mise. Trois étapes, je couvre la question. »*

---

## Q2 — Commenter EXPOSE et voir si ça marche

> *« Commentez ou supprimez l'instruction `EXPOSE` de vos Dockerfile. Reconstruisez l'image et redémarrez les conteneurs. Votre application fonctionne-t-elle toujours comme prévu ? »*

### Réponse

**Oui, ça marche toujours.** Voir le détail dans `10-transverses-reseau.md` (section EXPOSE vs ports:).

### La démo en live

```bash
# 1. Commenter dans spring-boot/Dockerfile :
# EXPOSE 8080  ← commenté

# 2. Rebuild
docker-compose build spring-boot

# 3. Up
docker-compose up -d

# 4. Test
curl http://localhost:8080
# → marche encore
```

### Explication

*« `EXPOSE` est purement documentaire. C'est une métadonnée stockée dans l'image (visible via `docker inspect`), mais elle n'ouvre **AUCUN** port en réalité. Ce qui ouvre vraiment le port, c'est le `ports: - "8080:8080"` dans le docker-compose, qui crée un mapping NAT sur l'hôte. C'est une confusion classique : les gens pensent qu'EXPOSE "ouvre" un port, en fait c'est juste un commentaire pour les humains et certains outils. »*

🎯 **À retenir** : *« EXPOSE ≈ commentaire structuré. Vrai mapping = `ports:` du compose. »*

### ⚠️ Piège bonus

Si le prof insiste : *« Donc ça sert à RIEN ? »*
- *« Pas tout à fait. EXPOSE est utilisé par `docker run -P` (P majuscule) qui auto-mappe tous les ports EXPOSED vers des ports aléatoires de l'hôte. C'est rarement utilisé en pratique (on préfère `-p 8080:8080` explicite), mais ça existe. Donc EXPOSE a une utilité, juste pas celle que les gens croient. »*

---

## Q3 — Changer le port Django de 8000 à 8050

> *« Modifiez le port utilisé dans l'application Django (par exemple, passez de 8000 à 8050). Quels ajustements sont nécessaires pour que l'ensemble de votre développement fonctionne ? »*

### Les 3 fichiers à toucher

**1. `django/Dockerfile`** :
```dockerfile
# AVANT
EXPOSE 8000
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]

# APRÈS
EXPOSE 8050
CMD ["python", "manage.py", "runserver", "0.0.0.0:8050"]
```

**2. `docker-compose.yml`** :
```yaml
# AVANT
django:
  ports:
    - "8000:8000"

# APRÈS
django:
  ports:
    - "8050:8050"
```

**3. `nginx/nginx.conf`** :
```nginx
# AVANT
upstream apps-ab {
    server spring-boot:8080;
    server django:8000;
}

# APRÈS
upstream apps-ab {
    server spring-boot:8080;
    server django:8050;
}
```

### Démo

```bash
docker-compose down
docker-compose up -d --build
curl http://localhost:80/test   # → doit alterner Spring et Django
curl http://localhost:8050      # → Django direct
```

### Réponse à l'oral

*« Trois endroits à toucher : 1) le `Dockerfile` de Django pour que le serveur écoute sur 8050 dedans, 2) le `docker-compose.yml` pour mapper le port hôte, 3) le `nginx.conf` pour que l'upstream pointe sur le nouveau port. Si j'oublie l'un des trois, ça pète : si j'oublie le Dockerfile, Django écoute toujours sur 8000 et `:8050` répond pas. Si j'oublie nginx.conf, le proxy va sur :8000 et trouve plus personne. »*

🎯 **À retenir** : *« 3 fichiers : Dockerfile (le serveur), compose (le mapping hôte), nginx.conf (le proxy). 3, pas 2. »*

### ⚠️ Subtilité

On pourrait aussi faire `"8050:8000"` dans le compose : le port interne reste 8000 (donc pas besoin de toucher au Dockerfile), mais le port hôte devient 8050. C'est une variante plus chirurgicale. Le prof testera surement la compréhension du **mapping host:container** : si la question dit "changer le port utilisé dans l'application", ça veut dire le port INTERNE (8050:8050), donc bien les 3 fichiers.

---

## Q4 — Ajouter/supprimer depends_on

> *« Modifiez votre fichier docker-compose.yml en ajoutant ou supprimant l'option `depends_on` pour l'un de vos services. [...] Expliquez l'impact. Pourquoi et quand est-il important d'utiliser cette option ? »*

### Notre conf actuelle

```yaml
nginx:
  depends_on:
    - spring-boot
    - django
```

Donc nginx démarre APRÈS spring-boot et django.

### Démo : supprimer depends_on

```bash
# Commenter les lignes depends_on dans docker-compose.yml
docker-compose down
docker-compose up -d
docker-compose logs nginx
# → tu verras potentiellement des erreurs "upstream not found" si nginx démarre AVANT les apps
```

### Réponse à l'oral

*« `depends_on` contrôle l'ordre de démarrage des services dans Docker Compose. Avec, nginx attend que spring-boot et django soient démarrés AVANT de se lancer. Sans, Docker peut les démarrer en parallèle, et nginx pourrait démarrer en premier alors que les apps ne sont pas encore prêtes — résultat : les premières requêtes upstream échouent. Quand est-ce que c'est important ? Dès qu'un service DÉPEND de la disponibilité d'un autre (un proxy a besoin de son backend, une app a besoin de sa base de données, etc.). »*

### ⚠️ Nuance importante

*« **Attention** : `depends_on` garantit que le PROCESSUS est démarré, pas que le service est PRÊT À RÉPONDRE. Si Django met 30 secondes à finir son boot (migrations, etc.), Nginx peut démarrer juste après le `python manage.py runserver` mais Django n'est pas encore en train d'écouter. Pour vraiment attendre la dispo réelle, il faut un `healthcheck` sur le service + `depends_on: condition: service_healthy`. C'est plus avancé, on ne l'a pas fait dans le projet pour rester simple. »*

🎯 **À retenir** : *« `depends_on` = ordre des PROCESS, pas dispo réelle. Pour la dispo réelle il faut un healthcheck. Ça reste utile pour la majorité des cas où le démarrage est rapide. »*

---

## Q5 — Ajouter SonarQube au pipeline

> *« Ajoutez l'analyse SonarQube à votre pipeline GitLab CI [...]. »*

### Honnêteté à l'oral

**Je n'ai PAS ajouté SonarQube** dans mon projet (la consigne ne le demandait pas, c'est une question hypothétique du prof). À l'oral, je peux soit faire l'ajout en live, soit décrire comment je l'ajouterais.

### Comment j'ajouterais

Il faudrait un job `sonar-scan` après le `test` stage :

```yaml
stages:
  - build
  - test
  - sonar       # ← nouveau stage
  - deploy
  - update

sonar-scan:
  stage: sonar
  image: sonarsource/sonar-scanner-cli:latest
  variables:
    SONAR_USER_HOME: "${CI_PROJECT_DIR}/.sonar"
    GIT_DEPTH: "0"
  script:
    - sonar-scanner
      -Dsonar.host.url=$SONAR_HOST_URL
      -Dsonar.login=$SONAR_TOKEN
      -Dsonar.projectKey=projet-66045
      -Dsonar.sources=spring-boot/src,django
  only:
    - main
```

Et il faudrait :
1. Avoir une instance SonarQube quelque part (SonarCloud gratuit, ou self-hosted)
2. Ajouter 2 variables GitLab CI : `SONAR_HOST_URL` et `SONAR_TOKEN`
3. Créer un projet dans SonarQube et récupérer la project key

### Ce que SonarQube remonterait

- **Bugs** : erreurs probables détectées (NullPointer, divisions par zéro, etc.)
- **Code smells** : violations de style/best practices (méthodes trop longues, complexité cyclomatique élevée, etc.)
- **Security hotspots** : zones de code à risque (input non validé, hardcoded passwords, etc.)
- **Coverage** : couverture des tests (avec un rapport JaCoCo pour Java, coverage.py pour Python)
- **Duplications** : code dupliqué entre fichiers

### Impact sur la qualité

*« Concrètement SonarQube me donnerait un dashboard avec une note (A/B/C/D/E) sur chacune des dimensions. On pourrait fixer un quality gate dans le pipeline qui fait FAIL le job si la note descend sous un seuil. Ça force à corriger avant de merger. Pour un projet réel ça monte la barre de qualité en continu. Pour notre projet académique ce serait un bonus, pas obligatoire. »*

🎯 **À retenir** : *« Pas fait, mais je sais comment je l'ajouterais : nouveau stage `sonar`, image `sonar-scanner-cli`, 2 variables CI (URL + token), et idéalement un quality gate. »*

---

## Q6 — Variable DEPLOY_ENV avec condition

> *« Ajoutez une variable personnalisée à votre pipeline GitLab CI [...]. Par exemple, créez un job qui ne se déclenche que si la variable DEPLOY_ENV est égale à production. »*

### Réponse

Dans `.gitlab-ci.yml`, on peut ajouter une variable globale + une règle conditionnelle :

```yaml
variables:
  DEPLOY_ENV: "staging"   # valeur par défaut

deploy-prod:
  stage: deploy
  image: mcr.microsoft.com/azure-cli
  script:
    - echo "Deploying to production..."
    - az webapp restart --name app-spring-66045 --resource-group rg-abtesting-66045
  rules:
    - if: '$DEPLOY_ENV == "production"'
      when: on_success
    - when: never
```

### Comment ça se déclenche

Cas 1 : push normal → `DEPLOY_ENV=staging` → règle pas matched → job pas exécuté.

Cas 2 : pipeline manuel avec override → dans GitLab UI "Run Pipeline" → ajouter variable `DEPLOY_ENV=production` → la règle matche → job s'exécute.

Cas 3 : push avec un commit qui exporte la variable (via un commit message ou autre) → idem.

### Réponse à l'oral

*« GitLab CI a un système de `rules` qui permet de conditionner l'exécution d'un job. La syntaxe `if: '$VAR == "valeur"'` fait que le job ne tourne que si la variable matche. Le `when: never` à la fin garantit qu'il ne tourne pas dans les autres cas. La variable elle-même peut être définie : 1) globalement dans le `.gitlab-ci.yml`, 2) dans les Settings → CI/CD → Variables, 3) au moment du déclenchement manuel via l'UI. C'est le pattern classique pour gérer des environnements multiples (dev/staging/prod) dans un seul pipeline. »*

🎯 **À retenir** : *« `rules: - if: '$VAR == "valeur"'` + `when: never` en fallback. Permet de gating un job sur une variable. »*

---

## Q7 — Pipeline déclenché uniquement sur tag spécifique

> *« Modifiez votre fichier .gitlab-ci.yml pour que le pipeline ne se déclenche uniquement lorsqu'un tag spécifique, par exemple présentation-2026, est poussé sur le dépôt. »*

### Réponse

On utilise un `workflow.rules` qui filtre sur `$CI_COMMIT_TAG` :

```yaml
workflow:
  rules:
    - if: '$CI_COMMIT_TAG == "presentation-2026"'
      when: always
    - when: never
```

Le `workflow:` agit au niveau global du pipeline (pas job par job).

### Démo

```bash
git tag presentation-2026
git push origin presentation-2026
# → un pipeline se déclenche

# Pour vérifier que ça filtre bien :
git commit --allow-empty -m "test push without tag"
git push
# → AUCUN pipeline ne se déclenche
```

### Réponse à l'oral

*« Avec `workflow.rules`, je conditionne le pipeline entier (pas un job individuel) à `$CI_COMMIT_TAG == "presentation-2026"`. GitLab injecte automatiquement `$CI_COMMIT_TAG` dans le contexte du pipeline quand c'est un push de tag. Si le tag matche, le pipeline tourne ; sinon `when: never` empêche tout. C'est utile pour les pipelines de release : on ne veut pas spam des pipelines à chaque commit dev, juste sur les milestones précis. »*

### Variables GitLab CI prédéfinies utiles

| Variable | Contenu |
|---|---|
| `$CI_COMMIT_BRANCH` | Nom de la branche (vide si tag) |
| `$CI_COMMIT_TAG` | Nom du tag (vide si branche) |
| `$CI_COMMIT_SHA` | Hash du commit |
| `$CI_PIPELINE_ID` | ID du pipeline |

🎯 **À retenir** : *« `workflow.rules` filtre tout le pipeline. `$CI_COMMIT_TAG` est la variable magique pour matcher sur un tag spécifique. C'est l'extension de la subtilité P3 où je disais qu'un push de tag déclenche 2 pipelines par défaut. »*

---

## Q8 — Partager une image buildée entre 2 jobs

> *« Vous avez construit une image Docker dans un job de votre pipeline. Modifiez le pipeline pour permettre à un autre job de partager et d'utiliser cette image déjà buildée. »*

### Approche 1 — Push vers un registre (ce qu'on fait déjà)

C'est exactement notre pattern P5 :

```yaml
push-spring:
  stage: deploy
  script:
    - docker build -t "$ACR_NAME.azurecr.io/spring-boot:latest" ./spring-boot
    - docker push "$ACR_NAME.azurecr.io/spring-boot:latest"

# Un autre job peut maintenant pull l'image :
test-deployed:
  stage: update
  script:
    - docker pull "$ACR_NAME.azurecr.io/spring-boot:latest"
    - docker run "$ACR_NAME.azurecr.io/spring-boot:latest" ...
```

### Approche 2 — Artifacts (pour partager un .tar)

```yaml
build-image:
  stage: build
  script:
    - docker build -t mon-app .
    - docker save mon-app > mon-app.tar
  artifacts:
    paths:
      - mon-app.tar
    expire_in: 1 hour

use-image:
  stage: test
  script:
    - docker load < mon-app.tar
    - docker run mon-app ...
```

### Réponse à l'oral

*« Il y a 2 approches. La PROPRE c'est de pusher l'image vers un registry (ce qu'on fait avec ACR en P5) : le job suivant pull la même image. Avantages : versionnée, traçable, persiste après le pipeline. La QUICK & DIRTY c'est de `docker save` l'image en .tar et de la passer en `artifacts` GitLab — le job suivant fait `docker load`. Plus rapide à mettre en place mais plus fragile et l'artifact expire. Notre projet utilise déjà l'approche 1 entre les jobs `push-*` et les vraies App Services Azure qui consomment l'image. »*

🎯 **À retenir** : *« Registre Docker = solution propre (notre cas). Artifacts GitLab = solution dépannage. »*

---

## Q9 — Schéma d'architecture avec ports + modification

> *« Sur un schéma représentant l'architecture de votre projet, indiquez les ports utilisés [...]. Modifiez le mapping : par exemple, changez le port interne d'une application pour 5050 et mappez-le sur le port 9090 sur votre machine hôte. Mettez à jour le schéma. »*

### Schéma actuel (à dessiner sur la feuille du prof si demandé)

```
   Machine hôte (Windows / Mac)
   ──────────────────────────────────────────────
   localhost:80   ─────────────────────────┐
   localhost:8080 ──────────────────┐      │
   localhost:8000 ─────────┐        │      │
                           │        │      │
   ┌───────────────────────┼────────┼──────┼─────┐
   │ Réseau Docker         │        │      │     │
   │ ab-network (bridge)   │        │      │     │
   │                       ▼        ▼      ▼     │
   │   ┌──────────┐ ┌────────────┐ ┌──────────┐  │
   │   │ django   │ │ spring-boot│ │ nginx-ab │  │
   │   │ :8000    │ │ :8080      │ │ :80      │  │
   │   └──────────┘ └────────────┘ └────┬─────┘  │
   │         ▲             ▲            │        │
   │         │             │            │        │
   │         └─────────────┴── proxy_pass /test  │
   │                                             │
   └─────────────────────────────────────────────┘
```

### Modification : Spring interne 5050, hôte 9090

```yaml
# Dans docker-compose.yml
spring-boot:
  ports:
    - "9090:5050"
```

```dockerfile
# Dans spring-boot/Dockerfile
EXPOSE 5050
```

ET aussi (point important) : il faut dire à Spring Boot d'écouter sur 5050 et pas 8080. Soit en variable d'env :
```yaml
spring-boot:
  environment:
    - SERVER_PORT=5050
```

OU en passant un arg au JAR :
```dockerfile
CMD ["java", "-jar", "/app/app.jar", "--server.port=5050"]
```

ET dans `nginx/nginx.conf` :
```nginx
upstream apps-ab {
    server spring-boot:5050;
    server django:8000;
}
```

### Nouveau schéma

```
   Machine hôte
   ──────────────────────────────────────────────
   localhost:9090 ──────────────────┐    (au lieu de 8080)
                                    │
   ┌────────────────────────────────┼──────────┐
   │ Réseau Docker ab-network        │          │
   │                                 ▼          │
   │   ┌────────────┐                            │
   │   │ spring-boot│:5050  (au lieu de 8080)    │
   │   └────────────┘                            │
   │                                             │
   └─────────────────────────────────────────────┘
```

### Réponse à l'oral

*« Le port interne du conteneur et le port externe sur l'hôte sont indépendants — c'est le `ports: "X:Y"` du compose qui les mappe. Mais attention, dans le cas de Spring Boot c'est pas que du mapping : Spring Boot a son propre paramètre `server.port` qui détermine où Tomcat écoute. Si je veux que Spring écoute en interne sur 5050, je dois lui dire via la variable `SERVER_PORT=5050` ou un argument `--server.port=5050`. Sinon il continue d'écouter 8080 même si EXPOSE dit 5050. Et il faut aussi mettre à jour `nginx.conf` parce que l'upstream pointe sur le port interne. »*

🎯 **À retenir** : *« Changer un port = 4 endroits potentiels : Dockerfile (EXPOSE), Dockerfile/env (le port que l'app écoute), docker-compose.yml (mapping hôte), nginx.conf (upstream). Pour Spring Boot c'est tricky parce qu'il a son propre param `server.port`. »*

---

## Q10 — Donner le Terraform au prof pour qu'il déploie sur SON Azure

> *« Imaginons que votre enseignant souhaite utiliser votre script Terraform pour déployer l'infrastructure sur son propre compte Azure. Quelles modifications ou configurations devez-vous apporter ? »*

### Réponse

Le prof n'a **rien à modifier dans mes fichiers `.tf`**. Il doit juste :

**1. Setup côté lui (1 fois)** :
```bash
# Installer Terraform et Azure CLI
brew install terraform azure-cli   # Mac

# Se logger sur son compte Azure
az login

# Récupérer son subscription_id
az account show --query id
```

**2. Adapter les variables avec son matricule** (parce que j'ai des noms genre `acrabtesting66045`, il devrait éviter d'utiliser le mien) :

Il crée un fichier `terraform.tfvars` à côté des `.tf` :
```hcl
acr_name             = "acrabtestingPROF1234"   # son matricule
spring_app_name      = "app-spring-PROF1234"
django_app_name      = "app-django-PROF1234"
resource_group_name  = "rg-abtesting-PROF1234"
```

**3. Lancer** :
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### Pourquoi ces modifs sont nécessaires

| Modif | Raison |
|---|---|
| `az login` côté prof | Pour s'authentifier en tant que LUI sur Azure |
| Changer `acr_name` | Le nom de l'ACR doit être globalement unique dans Azure. Si le prof réutilise `acrabtesting66045`, soit ça marche pas (déjà pris par moi), soit ça écrase mon ACR — pas propre. |
| Changer `*_app_name` | Idem, les noms d'App Service doivent être uniques globalement (`*.azurewebsites.net`). |
| Changer `resource_group_name` | Le RG doit être unique au sein de la souscription. Garder mon nom prête à confusion. |

### Réponse à l'oral

*« Le code Terraform est 100% portable parce que toutes les valeurs spécifiques (noms, région) sont dans `variables.tf` avec des défauts mais surchargeables. Le prof n'a rien à modifier dans mes `.tf` : il fait `az login` sur son compte, crée un `terraform.tfvars` avec ses propres noms (parce que les noms ACR et App Service sont globalement uniques sur Azure), et fait `terraform init` puis `apply`. C'est exactement le principe des variables Terraform : les valeurs métier sont externalisées, le code reste générique. »*

### ⚠️ Subtilité auth

Si le prof veut tester depuis SON pipeline GitLab à lui, il devra créer son propre Service Principal et configurer les 4 ARM_* dans son repo. Mais juste pour un test local avec `terraform apply` en CLI, `az login` interactif suffit (Terraform utilise alors la session CLI active).

🎯 **À retenir** : *« Tout passe par les variables. Rien de hardcodé en dehors de `variables.tf`. Le prof override avec `terraform.tfvars` ou via `-var` en CLI. »*

---

## Q11 — Identifier les ressources Azure créées par Terraform

> *« Exécutez votre script Terraform et identifiez les ressources Azure qui sont créées. Listez toutes les ressources déployées [...]. Expliquez le rôle de chaque ressource. »*

### Les 7 ressources

Détaillées dans `06-p4-terraform-azure.md`, voici le rappel :

| # | Ressource Terraform | Ressource Azure | Rôle |
|---|---|---|---|
| 1 | `azurerm_resource_group.rg` | Resource Group `rg-abtesting-66045` | Conteneur logique qui regroupe toutes les autres ressources. Permet de tout supprimer en un coup |
| 2 | `azurerm_user_assigned_identity.id_app` | Managed Identity `id-abtesting` | Identité Azure utilisée par les App Services pour s'authentifier au registre ACR. Zéro secret. |
| 3 | `azurerm_container_registry.acr` | Container Registry `acrabtesting66045` | Stocke mes images Docker (Spring + Django). Sert d'origine pour les déploiements. |
| 4 | `azurerm_role_assignment.acr_pull` | Role Assignment | Donne à la Managed Identity le rôle `AcrPull` sur l'ACR. Sans ça, les App Services ne pourraient pas pull les images. |
| 5 | `azurerm_service_plan.asp` | App Service Plan `asp-abtesting` (Linux B1) | Représente la capacité physique (CPU/RAM) qui fait tourner les App Services. Mutualisé entre Spring et Django pour économiser. |
| 6 | `azurerm_linux_web_app.spring` | App Service `app-spring-66045` | L'app Spring tournée comme conteneur. URL : `https://app-spring-66045.azurewebsites.net` |
| 7 | `azurerm_linux_web_app.django` | App Service `app-django-66045` | L'app Django tournée comme conteneur. URL : `https://app-django-66045.azurewebsites.net` |

### Démo à montrer

```bash
# Montrer ce que Terraform connaît
terraform state list

# Montrer ce qui est vraiment dans Azure
az resource list --resource-group rg-abtesting-66045 -o table

# Voir les URLs
az webapp show --name app-spring-66045 --resource-group rg-abtesting-66045 --query defaultHostName
az webapp show --name app-django-66045 --resource-group rg-abtesting-66045 --query defaultHostName
```

### Pourquoi chaque ressource est nécessaire

*« Le Resource Group c'est juste un dossier. Sans lui, les autres ressources n'auraient pas d'endroit où vivre. La Managed Identity et le Role Assignment sont indissociables : l'identité existe pour avoir des droits, le role assignment lui donne ces droits sur l'ACR. L'ACR c'est le frigo qui stocke mes images Docker — sans lui, les App Services ne sauraient pas d'où pull. Le Service Plan c'est la machine qui fait tourner les apps (CPU/RAM). Et les 2 App Services c'est les apps elles-mêmes : chacune pointe sur une image dans l'ACR, tire l'image au démarrage et fait tourner le conteneur. »*

🎯 **À retenir** : *« 7 ressources : 1 RG, 1 Identity, 1 ACR, 1 Role Assignment, 1 Service Plan, 2 App Services. Pas une de trop, pas une de manquante. »*

---

## Q12 — Suffixe `-ESI` sur toutes les images

> *« Vous souhaitez changer le nom de toutes les images Docker générées en y ajoutant le suffixe -ESI (par exemple, monimage-ESI). [...] »*

### Les fichiers à toucher

**1. `.gitlab-ci.yml` — jobs push-spring et push-django** :
```yaml
push-spring:
  script:
    - docker build -t "$ACR_NAME.azurecr.io/spring-boot-ESI:latest" ./spring-boot
    - docker push "$ACR_NAME.azurecr.io/spring-boot-ESI:latest"

push-django:
  script:
    - docker build -t "$ACR_NAME.azurecr.io/django-ESI:latest" ./django
    - docker push "$ACR_NAME.azurecr.io/django-ESI:latest"
```

**2. `terraform/variables.tf`** :
```hcl
variable "spring_image" {
  default = "spring-boot-ESI:latest"   # avant : spring-boot:latest
}

variable "django_image" {
  default = "django-ESI:latest"        # avant : django:latest
}
```

(C'est tout, parce que `main.tf` utilise déjà ces variables.)

**3. `docker-compose.yml`** (si on veut nommer aussi en local) :
```yaml
spring-boot:
  build: ./spring-boot
  image: spring-boot-ESI:latest   # ← nouvelle ligne
```

Sinon Docker Compose utilise un nom automatique `<dossier>_spring-boot`, pas grave en local.

### Pas besoin de toucher

- Les Dockerfile : le nom de l'image n'est PAS dans le Dockerfile, c'est dans la commande `docker build -t <nom>`.
- Le nginx.conf : les noms d'images ne sont pas référencés, on parle aux SERVICES par leur nom dans le compose (`spring-boot`, `django`).

### Démo

```bash
# Modifier les 3 fichiers ci-dessus
# Push un commit → pipeline tourne → images pushed avec nouveau nom

# Vérifier dans l'ACR
az acr repository list --name acrabtesting66045 -o table
# → doit montrer : spring-boot-ESI, django-ESI

# Vérifier que les App Services pullent bien la bonne nouvelle image
terraform apply   # → met à jour les App Services pour pointer sur le nouveau tag

# Tester
curl https://app-spring-66045.azurewebsites.net
# → doit toujours répondre
```

### Réponse à l'oral

*« Trois fichiers à modifier. Le `.gitlab-ci.yml` parce que c'est lui qui fait le `docker build -t <nom>:latest`. Le `terraform/variables.tf` parce que les App Services pointent sur ces noms via les variables `spring_image` et `django_image`. Et optionnellement le `docker-compose.yml` pour avoir le même nom en local. Le Dockerfile lui-même ne change pas : le nom est passé en argument au build, pas écrit dedans. C'est un bon exemple de pourquoi avoir variabilisé les noms d'image — un seul changement dans `variables.tf` propage partout dans Terraform. »*

🎯 **À retenir** : *« 3 fichiers : pipeline (le build/push), Terraform (où l'App Service pull), compose (pour le local). PAS le Dockerfile. »*

---

## Q13 — Supprimer .dockerignore et explorer le conteneur

> *« Supprimez un de vos fichiers .dockerignore, reconstruisez ensuite l'image Docker, lancez un conteneur à partir de cette image, puis explorez l'arborescence de fichiers à l'intérieur du conteneur. Montrez ce qui a été copié dans l'image et expliquez pourquoi la présence du fichier .dockerignore est importante. »*

### Démo

```bash
# 1. Backup pour pouvoir restaurer
cp django/.dockerignore django/.dockerignore.bak

# 2. Supprimer
rm django/.dockerignore

# 3. Rebuild (sans le .dockerignore → tout est copié)
docker-compose build django

# 4. Lancer
docker-compose up -d django

# 5. Entrer dans le conteneur
docker exec -it app-django sh

# Dans le conteneur :
cd /app
ls -la
# → tu vas voir :
#    .git/        ← TOUT l'historique git copié
#    .idea/       ← config IDE
#    db.sqlite3   ← base SQLite locale
#    __pycache__/ ← caches Python du build local
#    *.md         ← fichiers de doc inutiles
du -sh .git
# → la taille de .git peut être de plusieurs MB voire centaines de MB
exit

# 6. Stop le conteneur
docker-compose down

# 7. Restaurer
mv django/.dockerignore.bak django/.dockerignore

# 8. Rebuild propre
docker-compose build django
```

### Pourquoi `.dockerignore` est important

3 raisons majeures :

1. **Taille de l'image** : sans `.dockerignore`, l'historique git (parfois plusieurs centaines de MB) est embarqué. L'image gonfle inutilement.

2. **Sécurité** : l'historique git peut contenir des secrets que tu as accidentellement commités puis supprimés. Le fichier est supprimé du HEAD mais reste dans l'historique → un attaquant qui obtient l'image peut faire `git log -p` et récupérer le secret.

3. **Reproductibilité** : si tu copies ton `__pycache__/` local, l'image embarque les bytecodes Python compilés pour TA version de Python sur TON OS. Sur un autre OS, ça peut planter. Mieux vaut laisser Python recompiler les bytecodes au démarrage du conteneur (ce qui est de toute façon quasi-instantané).

### Réponse à l'oral

*« Sans .dockerignore, Docker copie TOUT le contenu du dossier dans l'image lors d'un `COPY . .`. Pour la démo, je supprime mon `.dockerignore` Django, je rebuild, j'entre dans le conteneur avec `docker exec -it`, et je `ls -la /app`. On voit alors le dossier `.git` complet, le `.idea`, des fichiers `*.md`, des caches Python. C'est important parce que : 1) ça gonfle l'image inutilement (potentiellement de plusieurs centaines de MB), 2) ça leak des données — l'historique git peut contenir des secrets que j'ai accidentellement commités, 3) la reproductibilité est cassée si je copie mes bytecodes compilés en local dans l'image. »*

🎯 **À retenir** : *« 3 raisons : taille, sécurité (leak via historique git), reproductibilité (cache local). Sans .dockerignore l'image est polluée et risquée. »*

---

## Stratégie d'oral générale

### Avant la question

1. **Écouter jusqu'au bout** — ne pas couper le prof.
2. **Reformuler** : « Si je comprends bien, vous me demandez X ? » → confirme la compréhension + gagne 5 sec de réflexion.

### Pendant la réponse

1. **Pointer le code** dans VS Code AVANT de parler ("Voilà le fichier concerné, ici à la ligne X...").
2. **Structure** : Ce que c'est → Ce que ça fait → Pourquoi je l'ai mis comme ça.
3. **Citer le TD** si pertinent ("J'ai suivi le pattern du TD 09 qui...").
4. **Bonus** : ajouter une nuance ou un piège pour montrer la profondeur ("À noter que ce comportement par défaut peut être changé avec...").

### Si je bloque

1. **Ne pas mentir** — admettre l'incertitude.
2. **Raisonnement à voix haute** : « Je ne suis pas certain, mais d'instinct je dirais X parce que Y. »
3. **Ouvrir une issue connue** : « Je sais qu'il y a une subtilité ici, je dois vérifier la doc... ».
4. **Demander si possible** : « Voulez-vous que je teste en live pour être sûr ? »

### Erreurs interdites

- ❌ Réciter sans comprendre
- ❌ Dire « je sais pas » sans tenter
- ❌ Mentir sur ce qu'on a pas fait (genre SonarQube)
- ❌ S'agacer / paraître stressé

🎯 **À retenir** : *« Montrer que je COMPRENDS, pas que je récite. Le prof teste la compréhension. »*

---

## Récap final — les 13 questions en une phrase chacune

| # | Sujet | Phrase clé |
|---|---|---|
| 1 | Expliquer une ligne | 3 étapes : qu'est-ce que c'est, ce que ça fait, pourquoi |
| 2 | EXPOSE supprimé | Marche toujours, EXPOSE c'est juste de la doc |
| 3 | Port Django 8000 → 8050 | 3 fichiers : Dockerfile, compose, nginx.conf |
| 4 | depends_on | Ordre des PROCESS, pas dispo réelle (faut healthcheck) |
| 5 | SonarQube | Pas fait. Si je le faisais : nouveau stage + image sonar-scanner-cli + 2 vars CI |
| 6 | DEPLOY_ENV conditionnel | `rules: - if: '$DEPLOY_ENV == "production"'` |
| 7 | Pipeline sur tag spécifique | `workflow.rules` avec `$CI_COMMIT_TAG == "presentation-2026"` |
| 8 | Partager image entre jobs | Push vers registre (notre cas) ou docker save + artifacts |
| 9 | Schéma ports + modif | 3 fichiers + Spring boot a son propre `server.port` |
| 10 | Donner Terraform au prof | Rien à changer dans `.tf`, juste un `terraform.tfvars` avec ses noms |
| 11 | Lister ressources | 7 : RG, Identity, ACR, Role Assignment, Service Plan, 2 App Services |
| 12 | Suffixe -ESI | 3 fichiers : pipeline, Terraform variables, compose. PAS Dockerfile |
| 13 | Supprimer .dockerignore | Image gonfle, git history embarqué, sécurité risque, reproductibilité cassée |

À relire en mode rapide la veille de la défense.
