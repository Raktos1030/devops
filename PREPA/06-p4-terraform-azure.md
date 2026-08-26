# Partie 4 — Infrastructure Azure (Terraform)

C'est la partie la plus dense du projet. Prends le temps.

## Ce que dit la consigne

> Imaginer les ressources Azure nécessaires (App Services, Container Registry...), créer le projet Terraform, déployer les 2 apps sur l'infrastructure, vérifier qu'elles répondent sur `/`. Tag `infrastructure`.
> **Remarque** : l'exécution de Terraform reste **manuelle** (pas de job pipeline).

## Ce qu'on a fait

Dans `terraform/` :
- `providers.tf` (déclaration du provider azurerm)
- `variables.tf` (9 variables avec défauts)
- `main.tf` (7 ressources Azure)
- `outputs.tf` (3 outputs : URL ACR + 2 URLs apps)
- `.terraform.lock.hcl` (lock des versions, versionné par recommandation TD 09)

Tag : **`infrastructure`** (sur le commit `202ae3e`)
Commits : `1deded8` (init providers + resource_group) + `202ae3e` (ACR + App Services)

## Vocabulaire Terraform

| Mot | Définition |
|---|---|
| **Infrastructure as Code (IaC)** | Décrire son infrastructure dans du code versionné (au lieu de cliquer dans une UI cloud). Reproductible, versionnable. |
| **HCL** | HashiCorp Configuration Language, le langage de Terraform. Déclaratif. |
| **Provider** | Plugin qui sait parler à une plateforme cloud (azurerm pour Azure, aws pour AWS, etc.). |
| **Resource** | Élément qu'on déclare (un Resource Group, un ACR, etc.). |
| **Variable** | Paramètre d'entrée du projet, peut avoir une valeur par défaut. |
| **Output** | Valeur affichée à la fin de `apply` (URLs, IDs des ressources créées, etc.). |
| **State (`.tfstate`)** | Fichier JSON qui mémorise ce que Terraform a créé. Indispensable pour comparer l'état souhaité (le code) avec l'état réel (le cloud). |

## Décortique du `providers.tf`

🔧 **Code** : `projet/terraform/providers.tf`

```hcl
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.66.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

### Ligne par ligne

| Bloc | À dire |
|---|---|
| `terraform { required_providers { ... } }` | « Bloc meta qui dit à Terraform quels providers il faut, et leur version. » |
| `source = "hashicorp/azurerm"` | « Provider azurerm officiel publié par HashiCorp sur le registry Terraform. » |
| `version = "4.66.0"` | « Pin de version exact : on est sûr d'utiliser cette version-là, pas une plus récente qui pourrait avoir des breaking changes. » |
| `provider "azurerm" { features {} }` | « Configuration du provider. `features {}` vide = on accepte les comportements par défaut. C'est obligatoire syntaxiquement même vide pour azurerm. » |

### 🎯 À retenir

*« Provider azurerm version 4.66.0 pinée. Le bloc `features {}` est obligatoire pour azurerm même vide. Aucun subscription_id dans le code → l'auth se fait via `az login` (local) ou les variables d'env `ARM_*` (en CI). »*

### ⚠️ Pièges potentiels

**« Pourquoi pas de `subscription_id` dans le `provider` ? »**
- *« Volontaire. Le provider azurerm cherche les credentials dans l'ordre : 1) variables d'env `ARM_*`, 2) session `az login`. En local j'ai `az login` actif → c'est utilisé automatiquement. Dans le pipeline CI on fournira `ARM_SUBSCRIPTION_ID` etc. en variables. Du coup le code Terraform est portable : le prof peut faire `az login` avec son compte et `terraform apply` chez lui sans rien modifier. »*

**« Pourquoi pinner exactement la version `4.66.0` ? »**
- *« Stabilité. Une nouvelle version mineure (4.67, 4.68...) pourrait introduire un changement de schéma sur une ressource et casser mon `apply`. En pinant exact, je suis sûr du comportement. Si je veux upgrader plus tard, je le fais explicitement. »*

**« C'est quoi le `.terraform.lock.hcl` ? »**
- *« Fichier auto-généré par `terraform init`. Il verrouille les versions exactes des providers utilisés (avec hash de vérification). Versionné dans le git d'après la doc TD 09 p.4, pour que quelqu'un d'autre qui clone ait exactement la même version. »*

## Décortique du `variables.tf`

🔧 **Code** : `projet/terraform/variables.tf`

```hcl
variable "location" {
  description = "Azure region"
  type        = string
  default     = "francecentral"
}

variable "resource_group_name" { ... default = "rg-abtesting-66045" }
variable "acr_name"            { ... default = "acrabtesting66045" }
variable "identity_name"       { ... default = "id-abtesting" }
variable "service_plan_name"   { ... default = "asp-abtesting" }
variable "spring_app_name"     { ... default = "app-spring-66045" }
variable "django_app_name"     { ... default = "app-django-66045" }
variable "spring_image"        { ... default = "spring-boot:latest" }
variable "django_image"        { ... default = "django:latest" }
```

### À savoir

| Variable | Valeur | Pourquoi cette valeur |
|---|---|---|
| `location` | `francecentral` | Azure for Students restreint les régions (policy `Allowed resource deployment regions`). `francecentral` est le plus proche de Bruxelles. |
| `resource_group_name` | `rg-abtesting-66045` | Convention `rg-` préfixe + matricule pour unicité dans le tenant |
| `acr_name` | `acrabtesting66045` | Noms ACR : 5-50 chars, **alphanumérique uniquement** (pas de tiret/underscore), globalement unique sur Azure |
| `spring_app_name`, `django_app_name` | `app-{spring/django}-66045` | Noms App Service globalement uniques (DNS public `*.azurewebsites.net`), tirets autorisés |

🎯 **À retenir** : *« 9 variables avec des défauts. Le prof peut tout overrider via `-var` ou un `terraform.tfvars`. Les noms incluent mon matricule 66045 pour garantir l'unicité globale (un ACR par exemple doit avoir un nom unique sur tout Azure mondial). »*

### ⚠️ Pièges potentiels

**« Pourquoi `francecentral` et pas `westeurope` comme dans le TD 09 ? »**
- *« Azure for Students applique une policy qui restreint les régions autorisées. Si je tape `westeurope` dans `location`, `terraform apply` plante avec une erreur policy. La liste autorisée chez moi : `francecentral, spaincentral, germanywestcentral, austriaeast, italynorth`. J'ai choisi `francecentral` parce que c'est le plus proche de Bruxelles donc la meilleure latence. »*

**« Comment vérifier les régions autorisées ? »**
- `az policy assignment list --query "[?displayName=='Allowed resource deployment regions'].parameters.listOfAllowedLocations.value" -o json`

**« Pourquoi les noms d'ACR sans tiret ? »**
- *« Contrainte Azure : un nom d'ACR doit être 5-50 caractères, **alphanumérique uniquement**. Pas de tiret, underscore ni point. Pour les App Services c'est différent, les tirets sont OK. »*

## Décortique du `main.tf`

🔧 **Code** : `projet/terraform/main.tf` (~80 lignes, 7 ressources)

```hcl
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_user_assigned_identity" "identity" {
  name                = var.identity_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.identity.principal_id
}

resource "azurerm_service_plan" "app_service_plan" {
  name                = var.service_plan_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "spring" {
  name                = var.spring_app_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.app_service_plan.id

  site_config {
    container_registry_use_managed_identity       = true
    container_registry_managed_identity_client_id = azurerm_user_assigned_identity.identity.client_id

    application_stack {
      docker_image_name   = var.spring_image
      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
    }
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.identity.id]
  }

  app_settings = {
    PORT = "8080"
  }
}

resource "azurerm_linux_web_app" "django" {
  # idem que spring, mais avec var.django_app_name, var.django_image, PORT = "8000"
}
```

### Les 7 ressources, leur rôle, et pourquoi elles sont là

| # | Ressource | Rôle |
|---|---|---|
| 1 | `azurerm_resource_group` | Conteneur logique qui regroupe toutes les autres ressources Azure du projet. Permet de tout supprimer d'un coup avec `terraform destroy`. |
| 2 | `azurerm_user_assigned_identity` | Identité Azure (sans mot de passe, gérée par Azure) qu'on va attacher aux App Services pour qu'ils s'authentifient à l'ACR. |
| 3 | `azurerm_container_registry` | Le registry Docker privé Azure où on push nos images Spring/Django. |
| 4 | `azurerm_role_assignment` | Attribution du rôle `AcrPull` à l'identité managée sur l'ACR. Sans ça, l'App Service ne peut pas pull l'image. |
| 5 | `azurerm_service_plan` | Le « plan tarifaire » App Service. Linux, SKU B1 (Basic, le moins cher qui supporte les conteneurs custom). Partagé entre les 2 web apps pour économiser. |
| 6 | `azurerm_linux_web_app` (spring) | L'App Service qui exécute le conteneur Spring Boot. Lié au plan B1, à l'identité managée, et configuré pour pull `spring-boot:latest` depuis l'ACR. |
| 7 | `azurerm_linux_web_app` (django) | Idem pour Django. |

### 🎯 À retenir pour chaque ressource

**Resource Group** (`azurerm_resource_group "rg"`)
- *« Conteneur logique Azure. Tout ce que je crée est dans ce RG. Pour démolir d'un coup, `terraform destroy` (ou suppression du RG entier sur le portail). »*

**Identité managée** (`azurerm_user_assigned_identity "identity"`)
- *« Identité Azure sans mot de passe, gérée par Azure. Avantage : pas de credentials à stocker dans le code ou dans des secrets. Les App Services s'authentifient avec cette identité pour parler à l'ACR. »*

**ACR** (`azurerm_container_registry "acr"`)
- *« Mon registry Docker privé Azure. SKU `Basic` (le moins cher), `admin_enabled = true` (active un user/password admin si besoin, même si on utilise l'identité managée). »*

**Role assignment** (`azurerm_role_assignment "acr_pull"`)
- *« Le truc qui dit "cette identité a le droit de pull depuis cet ACR". Rôle `AcrPull` (lecture des images), pas `AcrPush` (parce que c'est le pipeline qui push, pas l'App Service). Principe du moindre privilège. »*

**Service Plan** (`azurerm_service_plan "app_service_plan"`)
- *« Le tier de calcul App Service. `Linux` parce que nos conteneurs sont Linux, `B1` parce que c'est le moins cher qui supporte les custom containers. Les Free/Shared ne supportent pas Docker custom. »*

**Linux Web App** (`azurerm_linux_web_app "spring"` et `"django"`)
- Bloc `site_config` : configure l'auth ACR par managed identity + l'image Docker à utiliser
- Bloc `identity` : attache notre identité managée
- Bloc `app_settings` : variables d'env passées au conteneur (notre `PORT`)

### ⚠️ Pièges potentiels MAJEURS

**« Pourquoi `PORT` et pas `WEBSITES_PORT` ? »**
- *« TD 08 le précise : "Azure modifie actuellement sa gestion des conteneurs, ajoutez une variable PORT (et non plus WEBSITES_PORT) avec la valeur 8000". J'ai utilisé `PORT`. Avec `WEBSITES_PORT`, Azure tenterait de joindre le conteneur sur le port 80 par défaut et l'app retournerait une erreur. »*

**« Pourquoi un seul Service Plan partagé entre les 2 web apps ? »**
- *« Économie de coûts : un Service Plan B1 fait tourner plusieurs apps. Si j'avais fait 2 Service Plans, je paierais 2x. La consigne demande de "imaginer la quantité de ressources nécessaires" → un seul suffit pour 2 petites apps. »*

**« Pourquoi `admin_enabled = true` sur l'ACR si on utilise l'identité managée ? »**
- *« Avoir l'admin user activé permet aussi le `docker login` classique avec username/password, ce qui dépanne pour le pipeline CI (qui utilise les credentials du Service Principal pour `docker login`). Sans `admin_enabled`, il faudrait passer par d'autres méthodes plus complexes. »*

**« Pourquoi 2 ressources `azurerm_linux_web_app` quasi identiques ? Pourquoi pas une boucle `for_each` ? »**
- *« Choix de lisibilité. `for_each` existe en Terraform (vu en TD 09 p.12), mais avec seulement 2 apps qui ont des configs légèrement différentes (port, image), l'explicite est plus clair. Si j'avais 10 apps, j'aurais utilisé `for_each`. »*

**« Si tu déploies ce script sur le compte Azure de quelqu'un d'autre, que dois-tu modifier ? »** (Question 10 du prof)
- *« Rien dans le code en théorie. Il fait `az login` avec SON compte, lance `terraform apply`, et le provider azurerm utilise sa session active automatiquement. Si sa subscription a une policy de régions différente, il devra peut-être ajuster la variable `location` (via `-var="location=westeurope"` par exemple). Si les noms `acrabtesting66045` ou `app-spring-66045` sont déjà pris globalement, il devra aussi les changer. Mais aucune modification du code source en soi. »*

## Décortique du `outputs.tf`

🔧 **Code** : `projet/terraform/outputs.tf`

```hcl
output "acr_login_server" {
  description = "URL of the Azure Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "spring_app_url" {
  description = "URL of the Spring Boot web app"
  value       = "https://${azurerm_linux_web_app.spring.default_hostname}"
}

output "django_app_url" {
  description = "URL of the Django web app"
  value       = "https://${azurerm_linux_web_app.django.default_hostname}"
}
```

🎯 **À retenir** : *« 3 outputs affichés à la fin du `apply` : l'URL de l'ACR et les URLs publiques des 2 apps. Pratique pour récupérer rapidement les infos sans aller cliquer dans le portail. »*

## Les commandes Terraform utiles

| Commande | Rôle |
|---|---|
| `terraform init` | Télécharge les providers (la 1ère fois), crée le dossier `.terraform/` |
| `terraform fmt` | Formate le code (indentation propre) |
| `terraform validate` | Vérifie la syntaxe et la cohérence des fichiers `.tf` |
| `terraform plan` | Affiche ce qui SERAIT créé/modifié/supprimé sans rien faire |
| `terraform apply` | Crée/modifie/supprime pour atteindre l'état déclaré dans les `.tf` |
| `terraform destroy` | Détruit tout ce qui est dans le state |
| `terraform state list` | Liste les ressources actuellement dans le state |
| `terraform state show <name>` | Détails d'une ressource du state |

## Mini-récap pour P4

| Question | Réponse |
|---|---|
| Combien de ressources Azure créées par notre Terraform ? | 7 |
| Quelles ressources ? | resource_group, identity, container_registry, role_assignment, service_plan, 2× linux_web_app |
| Pourquoi `francecentral` ? | Azure for Students restreint les régions, c'est la plus proche de Bruxelles dans la liste autorisée |
| Pourquoi `PORT` et pas `WEBSITES_PORT` ? | Azure a changé sa gestion des conteneurs, TD 08 le précise |
| Pourquoi un seul Service Plan ? | Économie : un plan B1 héberge plusieurs apps |
| Pourquoi SKU `Basic` pour ACR ? | Le moins cher, suffisant pour stocker 2 images |
| Pourquoi `azurerm_role_assignment` `AcrPull` ? | Donne à l'identité managée le droit de pull les images. Sans ça l'App Service ne peut pas accéder à l'ACR. |
| Pourquoi 2 web apps quasi identiques au lieu de `for_each` ? | Lisibilité pour 2 apps. `for_each` aurait été utile si on en avait 10. |
| Comment le prof peut-il utiliser mon Terraform ? | `az login` avec son compte, `terraform apply`. Peut-être ajuster `location` si sa policy diffère. |
| Comment fonctionne le state ? | Fichier `.tfstate` JSON qui mémorise ce que Terraform a créé. Compare état réel (cloud) vs souhaité (code) pour décider quoi faire. |
| Pourquoi `.terraform.lock.hcl` est versionné ? | TD 09 le recommande : assure que tout le monde utilise les mêmes versions exactes de providers |
