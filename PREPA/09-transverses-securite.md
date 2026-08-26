# Transverse — Sécurité, secrets, fichiers exclus

Cette section regroupe tout ce qui touche à la **sécurité du repo** et à la **gestion des secrets**. C'est un classique des questions de défense, surtout sur `.dockerignore` (Question 13 du prof) et sur la séparation Service Principal / Managed Identity.

## Les fichiers à exclure (et où)

| Outil | Fichier | Ce qu'il exclut | Pourquoi |
|---|---|---|---|
| Git | `.gitignore` | `terraform.tfstate*`, `.terraform/`, `terraform.tfvars`, `*.jar`, `__pycache__/`, `target/`, `db.sqlite3`, `.idea/`, `.vscode/` | Évite de pousser : artefacts de build, état Terraform (contient les secrets en clair !), credentials, fichiers IDE perso |
| Docker | `.dockerignore` | `.git/`, `target/`, `__pycache__/`, `*.md`, `.idea/`, `.vscode/` | Évite d'empaqueter dans l'image : l'historique git complet (poids ÉNORME et leak potentiel), les builds locaux (à rebuilder dans le conteneur), les fichiers de dev |

🎯 **À retenir** : *« `.gitignore` c'est pour git, `.dockerignore` c'est pour Docker. Deux fichiers différents, deux contextes différents. »*

## `.gitignore` — décortique

🔧 **Code** : `projet/.gitignore`

```
# Java / Spring Boot
target/
*.jar
*.class
.mvn/

# Python / Django
__pycache__/
*.pyc
db.sqlite3

# Terraform
.terraform/
*.tfstate
*.tfstate.backup
*.tfvars
.terraform.lock.hcl

# IDE
.idea/
.vscode/
*.iml

# OS
.DS_Store
Thumbs.db
```

⚠️ **Subtilité importante** : on garde `.terraform.lock.hcl` **DANS** le repo en réalité, parce que c'est lui qui fixe la version exacte du provider pour la reproductibilité. La règle générale dit "exclure", mais Terraform a renversé cette pratique récemment (le lock est versionné comme `package-lock.json`).

🎯 **À retenir** : *« On exclut surtout 3 catégories : 1) les artefacts compilés (target/, *.jar, *.pyc, __pycache__), 2) les états Terraform qui contiennent les secrets en clair, 3) les fichiers IDE perso. On NE met PAS le terraform.tfstate dans git parce qu'il a les credentials et que ça serait une catastrophe sécurité. »*

### ⚠️ Piège : pourquoi `terraform.tfstate` est dangereux dans git ?

- Il contient les sorties (URLs, IDs, etc.) en clair.
- Il peut contenir des secrets (passwords, clés) **en clair**.
- Il évolue à chaque `terraform apply` → conflits permanents si plusieurs personnes travaillent dessus.
- Solution prod : backend distant (Azure Storage, S3...) avec verrouillage. Hors scope du projet.

## `.dockerignore` — décortique (Question 13 du prof)

🔧 **Code** : `projet/spring-boot/.dockerignore` et `projet/django/.dockerignore`

```
.git
.gitignore
target/
*.iml
.idea/
.vscode/
*.md
```

### Pourquoi c'est important

Sans `.dockerignore`, Docker copie **TOUT** le contenu du contexte de build (le dossier passé à `docker build`) avant de jouer les `COPY`. Ça veut dire :
- L'historique `.git` complet (plusieurs MB voire GB) dans l'image
- Le `target/` ou `__pycache__/` du build local mélangé au build clean dans le conteneur
- Les `.idea/` avec parfois des tokens API mis dans des fichiers de config
- Des `*.md` qui n'ont rien à faire dans un conteneur de prod

🎯 **À retenir** : *« .dockerignore réduit la taille du contexte de build, accélère le build, et surtout évite de leak des trucs sensibles comme l'historique git ou des fichiers de config IDE. Sans lui, l'image grossirait inutilement et risquerait d'embarquer des données privées. »*

### La démo Question 13

Le prof peut demander : *« supprime ton `.dockerignore`, rebuild, lance le conteneur, explore l'arborescence »*. Procédure :

```bash
# 1. Supprimer
rm django/.dockerignore

# 2. Rebuild
docker-compose build django

# 3. Lancer + explorer
docker-compose up -d django
docker exec -it app-django sh
# Dans le conteneur :
ls -la /app
# Tu vas voir .git/ (énorme), .idea/, db.sqlite3, etc.
exit

# 4. Restaurer .dockerignore
git checkout django/.dockerignore
docker-compose build django
```

## La séparation des secrets (Service Principal vs Managed Identity)

C'est un **point fort** à mettre en avant à l'oral.

### Service Principal — c'est quoi

Un compte d'application Azure, créé manuellement par moi via `az ad sp create-for-rbac`. Il donne 4 valeurs : `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID`. Ces 4 valeurs sont configurées en variables **masked + protected** dans GitLab.

🎯 **À retenir** : *« Le Service Principal c'est pour le PIPELINE. Mon Terraform et mes commandes `az` dans GitLab s'authentifient avec ces credentials, sans passer par mon compte personnel. C'est comme un "compte robot" dédié à la CI. »*

### Managed Identity — c'est quoi

Une identité Azure attachée DIRECTEMENT à mes App Services. Elle est créée par Terraform (`azurerm_user_assigned_identity`), assignée à chaque webapp, et autorisée à pull les images de mon ACR via un `azurerm_role_assignment` avec le rôle `AcrPull`.

🎯 **À retenir** : *« La Managed Identity c'est pour l'EXÉCUTION sur Azure. Pas de credentials qui traînent : Azure sait que cette App Service a le droit de pull cette image, sans mot de passe. C'est le pattern le plus propre, recommandé par le TD 09. »*

### Tableau récap des deux

| Aspect | Service Principal | Managed Identity |
|---|---|---|
| Création | Manuelle (`az ad sp create-for-rbac`) | Automatique (Terraform `azurerm_user_assigned_identity`) |
| Usage | Pipeline CI (Terraform, `docker push`, `az webapp restart`) | App Service Azure → pulls image depuis ACR |
| Credentials | Client ID + Client Secret (à stocker, masqués dans GitLab) | Aucun secret, l'identité est gérée par Azure |
| Si fuite | Catastrophe (faire `az ad sp delete` + recréer) | Pas applicable (rien à fuiter) |
| Sécurité | Moyenne — un secret qui circule | Forte — zéro secret |

### ⚠️ Pièges potentiels

**« Pourquoi pas tout faire en Managed Identity ? »**
- *« Bonne question. La Managed Identity ne s'utilise QUE depuis une ressource Azure (App Service, VM...). Mon pipeline tourne sur ma machine locale (le GitLab Runner est chez moi), pas sur Azure → il ne peut pas utiliser de Managed Identity, il faut un Service Principal. Si je migrais mon runner vers une VM Azure, je pourrais alors le faire authentifier en Managed Identity et supprimer le Service Principal. »*

**« Et le `ARM_CLIENT_SECRET`, on le tourne tous les combien ? »**
- *« En prod, idéalement tous les 90 jours. Pour ce projet académique, on l'a créé en début de P5 et on le révoquera après la défense (`az ad sp delete --id $ARM_CLIENT_ID`). C'est important parce qu'un secret qui traîne après la fin du projet est un risque. »*

**« Et si quelqu'un clone mon repo, il peut faire du mal ? »**
- *« Non. Les secrets ne sont PAS dans le repo : ils sont dans **GitLab CI Variables**. Le repo ne contient que des références (`$ARM_CLIENT_ID`) qui sont des shell variables, vides sauf dans le contexte d'un job de pipeline. Si quelqu'un clone, il a juste le code, pas l'accès Azure. »*

## Les variables GitLab CI — masked vs protected

Dans Settings → CI/CD → Variables, chaque variable a 2 options :

| Option | Comportement |
|---|---|
| **Masked** | La valeur est cachée dans les logs (apparaît comme `[MASKED]`). Empêche un `echo` accidentel de leaker le secret. |
| **Protected** | La variable n'est passée qu'aux pipelines tournant sur une branche/tag **protégée**. Évite qu'un attaquant push une branche feature avec un `echo $ARM_CLIENT_SECRET` pour exfiltrer. |

🎯 **À retenir** : *« Les 5 variables (4 ARM + ACR_NAME) sont **toutes en masked**. ARM_CLIENT_SECRET est aussi en **protected** parce que c'est le plus sensible. C'est la double ceinture-bretelles. »*

### ⚠️ Limite de masked

Pour qu'une variable soit **maskable**, sa valeur doit respecter certaines règles GitLab : au moins 8 caractères, base64 standard. Si ton secret contient un `=` ou un caractère exotique, GitLab refuse de la masker. Solution : `az ad sp create-for-rbac` sort des secrets compatibles, donc pas eu le souci.

## Le LABEL `author="66045"` dans les Dockerfiles

🔧 **Code** : présent dans tous les Dockerfiles (`spring-boot/`, `django/`, `nginx/`, `nginx-azure/`)

```dockerfile
LABEL author="66045"
```

Pas un secret, mais un point de **traçabilité**. Quand l'image tourne en prod, `docker inspect` te renvoie le LABEL → on sait qui a buildé. Pratique pour audit. La consigne du projet l'exige (matricule = signature).

🎯 **À retenir** : *« Le LABEL c'est ma signature dans l'image. Quand l'image est sur ACR ou dans un conteneur en cours d'exécution, `docker inspect image_id | grep -i author` me ressort '66045'. C'est mon matricule. »*

## Le multi-stage build comme protection

Rappel de la P1 mais c'est aussi une mesure de sécurité :

```dockerfile
FROM maven:3.9-eclipse-temurin-21 AS build
# ... build ici
FROM eclipse-temurin:21-jre-alpine
COPY --from=build /app/target/*.jar app.jar
```

L'image finale contient **juste le JRE et le JAR**. Pas Maven, pas le JDK, pas les sources Java. → Surface d'attaque réduite : si une CVE sort sur Maven, mon conteneur de prod n'est pas exposé puisqu'il ne contient pas Maven.

🎯 **À retenir** : *« Multi-stage build = sécurité bonus : l'image de prod ne contient pas les outils de build. Si une faille sort sur Maven, mes apps déployées ne sont pas concernées parce que Maven n'est tout simplement pas dedans. »*

## La conf Django allowed_hosts (point fin)

Dans `django/djangoAbTesting/settings.py` (donné par l'école) il y a :
```python
ALLOWED_HOSTS = ["*"]
```

C'est volontairement permissif pour le projet. **En prod**, on mettrait `["app-django-66045.azurewebsites.net"]` pour empêcher quelqu'un de monter une attaque de type Host header injection.

🎯 **À retenir** : *« ALLOWED_HOSTS=['*'] c'est OK pour un projet académique mais en prod réelle on restreindrait à la liste explicite des domaines autorisés. C'est une décision conscience-de-sécurité, pas un oubli. »*

## Mini-récap sécurité

| Question | Réponse |
|---|---|
| Qu'est-ce qu'on exclut de git ? | terraform.tfstate, .terraform/, terraform.tfvars, target/, __pycache__/, .idea/, .vscode/ |
| Qu'est-ce qu'on exclut du build Docker ? | .git, target/, __pycache__/, *.md, .idea/ — pour réduire la taille de l'image et éviter les leaks |
| Pourquoi NE PAS pousser terraform.tfstate ? | Il contient potentiellement des secrets en clair |
| Où sont stockés les secrets Azure ? | Dans GitLab Settings → CI/CD → Variables, en masked + protected |
| Service Principal vs Managed Identity ? | SP = compte robot pour le pipeline (mes credentials), MI = identité Azure native pour les App Services (zéro secret) |
| À quoi sert le LABEL author="66045" ? | Traçabilité de l'auteur de l'image, visible via docker inspect |
| Multi-stage build en sécurité ? | L'image finale ne contient pas Maven/JDK, juste le JRE → surface d'attaque réduite |
| Quand révoquer le Service Principal ? | Après la défense : `az ad sp delete --id $ARM_CLIENT_ID` |
