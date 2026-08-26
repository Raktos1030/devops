# Transverse — Azure, Service Principal, variables CI

Ce fichier compile **toute la machinerie Azure** : comment je m'authentifie depuis le pipeline, où sont les secrets, comment Terraform les utilise. C'est le point qui peut le plus me déstabiliser à l'oral si je connais pas par cœur.

## La chaîne d'auth complète

```
Mon repo GitLab
    │
    │ contient .gitlab-ci.yml qui référence
    │ $ARM_CLIENT_ID, $ARM_CLIENT_SECRET, etc.
    │
    ▼
GitLab Variables (Settings → CI/CD → Variables)
    │ 5 vars : ARM_CLIENT_ID, ARM_CLIENT_SECRET,
    │          ARM_TENANT_ID, ARM_SUBSCRIPTION_ID, ACR_NAME
    │ tous "masked", ARM_CLIENT_SECRET aussi "protected"
    │
    ▼
Le job tourne → Variables injectées dans l'env du conteneur Docker
    │
    ▼
Le job fait soit :
    │ - terraform apply → utilise les ARM_* automatiquement
    │ - docker login + docker push → utilise CLIENT_ID + CLIENT_SECRET
    │ - az login --service-principal → utilise tous les 4
    │
    ▼
Azure répond avec un token d'accès
    │
    ▼
Le job exécute son action (créer ressources / pusher image / restart webapp)
```

## Le Service Principal — création et identifiants

### Comment je l'ai créé

```bash
az ad sp create-for-rbac \
  --name "sp-devops-66045" \
  --role Contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID
```

Sortie (exemple — valeurs réelles à révoquer après défense) :
```json
{
  "appId": "xxxx-xxxx-xxxx",        ← ARM_CLIENT_ID
  "displayName": "sp-devops-66045",
  "password": "yyyy-yyyy-yyyy",     ← ARM_CLIENT_SECRET
  "tenant": "zzzz-zzzz-zzzz"        ← ARM_TENANT_ID
}
```

Et l'ID de souscription (`ARM_SUBSCRIPTION_ID`) je l'ai eu avec `az account show --query id`.

🎯 **À retenir** : *« Le Service Principal je l'ai créé avec `az ad sp create-for-rbac`. La commande me sort 3 valeurs (appId, password, tenant), je récupère aussi l'ID de souscription via `az account show`. Ces 4 valeurs deviennent les variables ARM_* dans GitLab. »*

### Pourquoi rôle `Contributor` ?

C'est le minimum pour pouvoir créer/modifier/supprimer toutes les ressources Azure du projet (RG, ACR, App Services, etc.). On pourrait être plus granulaire (`AcrPush` + `Website Contributor` + `Reader`...) mais pour un projet académique, `Contributor` sur la souscription c'est OK.

⚠️ **En vraie prod** : on prendrait un rôle minimal (principe du least privilege) et on scoperait au resource group plutôt qu'à la souscription complète.

🎯 **À retenir** : *« Contributor sur la souscription, c'est large mais ça marche. En prod réelle on serait plus restrictif avec des rôles custom et un scope limité au Resource Group. »*

## Les 5 variables CI dans GitLab — détail

| Variable | Origine | À quoi ça sert | Masked | Protected |
|---|---|---|---|---|
| `ARM_CLIENT_ID` | `appId` du SP | Identifier le SP pour Terraform / az login | ✅ | ❌ |
| `ARM_CLIENT_SECRET` | `password` du SP | Authentifier le SP | ✅ | ✅ |
| `ARM_TENANT_ID` | `tenant` du SP | Identifier le tenant Azure AD | ✅ | ❌ |
| `ARM_SUBSCRIPTION_ID` | `az account show --query id` | Identifier la souscription Azure cible | ✅ | ❌ |
| `ACR_NAME` | Choix du dev | Préfixer le tag d'image (`$ACR_NAME.azurecr.io/...`) | ❌ | ❌ |

🎯 **À retenir** : *« 5 variables au total. 4 pour l'auth Azure (ARM_*) + 1 pour le nom de l'ACR. CLIENT_SECRET est masked **et** protected, les autres juste masked. »*

### Pourquoi `ACR_NAME` n'est pas un secret ?

Le nom de l'ACR n'est pas un secret en soi : `acrabtesting66045.azurecr.io` ce n'est qu'une URL. Ce qui est secret c'est le mot de passe qu'on utilise pour s'y logger (= `ARM_CLIENT_SECRET`). Mais on a quand même variabilisé `ACR_NAME` pour la **propreté** : si on change de nom d'ACR un jour, on modifie juste la variable au lieu de tout réécrire dans le pipeline.

## Le mapping ARM_* → Terraform

Le provider `azurerm` détecte **automatiquement** les variables d'env qui commencent par `ARM_*`. C'est pourquoi dans `providers.tf` on a juste :

```hcl
provider "azurerm" {
  features {}
}
```

Sans aucun `client_id =`, `client_secret =`, etc. Terraform va lire les variables d'env. C'est la convention recommandée.

🎯 **À retenir** : *« Le provider azurerm lit `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID` et `ARM_SUBSCRIPTION_ID` automatiquement depuis l'environnement. Je n'écris pas ces valeurs dans le fichier `providers.tf` — c'est ce qui me permet d'avoir un fichier `.tf` propre et committable sans secrets. »*

### ⚠️ Pièges potentiels

**« Et si tu écrivais les credentials direct dans `providers.tf` ? »**
- *« Ça marcherait mais ça serait catastrophique : le fichier est commité, les credentials se retrouvent dans git, l'historique git est éternel. La bonne pratique c'est exactement ce qu'on fait : variables d'env, provider vide. »*

**« Et terraform.tfvars, pourquoi pas mettre les secrets dedans ? »**
- *« On pourrait, mais `terraform.tfvars` est dans le `.gitignore`. C'est juste OK si ton workflow c'est `terraform apply` en local manuel. Dans notre pipeline CI, c'est plus simple de passer par les variables d'env ARM_*, donc on n'utilise même pas de `terraform.tfvars` dans le pipeline. »*

## Les 9 variables Terraform (pas les ARM_*)

Ces variables sont dans `terraform/variables.tf` et représentent les **paramètres métier** de l'infra (noms, région, images) — pas des secrets.

| Variable | Valeur par défaut | Rôle |
|---|---|---|
| `location` | `francecentral` | Région Azure (limitée par Azure for Students) |
| `resource_group_name` | `rg-abtesting-66045` | Conteneur logique pour toutes les ressources |
| `acr_name` | `acrabtesting66045` | Nom unique global de mon ACR |
| `identity_name` | `id-abtesting` | Nom de la Managed Identity |
| `service_plan_name` | `asp-abtesting` | Nom du Service Plan (capacité partagée) |
| `spring_app_name` | `app-spring-66045` | Nom de l'App Service Spring |
| `django_app_name` | `app-django-66045` | Nom de l'App Service Django |
| `spring_image` | `spring-boot:latest` | Tag d'image Spring à utiliser |
| `django_image` | `django:latest` | Tag d'image Django à utiliser |

🎯 **À retenir** : *« 9 variables Terraform, toutes avec des `default` raisonnables. Pas de secrets dedans — uniquement des noms et la région. Les secrets passent par les ARM_* qui sont des variables d'env, pas des `variable {}` Terraform. »*

### Pourquoi `francecentral` ?

Azure for Students restreint les régions disponibles. Quand on essaie de créer une ressource dans une région non autorisée, Azure renvoie une erreur "policy violation". Les régions autorisées chez moi : `francecentral`, `spaincentral`, `germanywestcentral`, `austriaeast`, `italynorth`. J'ai choisi `francecentral` pour être proche de la Belgique → latence minimale.

🎯 **À retenir** : *« Azure for Students limite les régions disponibles via des Azure Policy. J'ai choisi `francecentral` parce que c'est la plus proche de Bruxelles dans les options autorisées. C'est testable avec `az policy assignment list`. »*

## Comment Azure se vérifie au moment du `az login`

Le job `update-spring` (et update-django) fait :
```yaml
- az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
```

Ce que fait Azure :
1. Reçoit `client_id` + `client_secret` + `tenant_id`
2. Cherche dans Azure AD du tenant indiqué un Service Principal avec ce `client_id`
3. Vérifie que le `client_secret` est valide pour ce SP
4. Renvoie un token JWT (valable 1h, renouvelable)
5. La CLI stocke ce token, les commandes suivantes (`az webapp restart`, etc.) l'utilisent

🎯 **À retenir** : *« `az login --service-principal` c'est OAuth2 sous le capot : je présente mon client_id + secret + tenant, Azure me retourne un token JWT que la CLI réutilise pour toutes les opérations suivantes. Le token expire après 1h mais comme un job dure quelques minutes, ça suffit largement. »*

## La séquence Push image (job `push-spring` — TON vrai fichier)

```yaml
push-spring:
  stage: deploy
  image: docker:latest
  script:
    - docker login "$ACR_NAME.azurecr.io" -u "$ARM_CLIENT_ID" --password "$ARM_CLIENT_SECRET"
    - docker build -t "$ACR_NAME.azurecr.io/spring-boot:latest" ./spring-boot
    - docker push "$ACR_NAME.azurecr.io/spring-boot:latest"
```

Notes (calibré sur ton VRAI pipeline) :
- `image: docker:latest` : le job tourne dans un conteneur qui contient le **client `docker`** (la CLI).
- **PAS de `services: docker:dind`.** Ton job utilise le **démon Docker de l'HÔTE** : ton runner a été enregistré avec `--docker-volumes /var/run/docker.sock:/var/run/docker.sock`, donc chaque job a accès au socket Docker de ta machine. C'est la technique **« accès au démon hôte »** du TD 07 (p.20-22), PAS le Docker-in-Docker.
- `docker login ... --password "$ARM_CLIENT_SECRET"` : c'est la **forme exacte de la consigne** (`--password` via la variable, pas `--password-stdin`).

🎯 **À retenir** : *« Pour pusher vers ACR depuis le pipeline, je me logge avec le Service Principal comme un utilisateur ACR. Mon job tourne dans une image `docker:latest` (qui a la CLI docker), et il parle au démon Docker de l'hôte via le socket monté dans le runner — c'est l'approche "accès au démon hôte" du TD 07, pas du dind. »*

### ⚠️ Pièges potentiels

**« Tu utilises Docker-in-Docker (dind) ? »**
- *« Non. Le TD 07 montre deux techniques pour faire du docker dans un pipeline (p.20-22) : (1) l'accès au démon hôte via le socket `/var/run/docker.sock`, et (2) le Docker-in-Docker avec `services: docker:dind`. J'utilise la (1) : mon runner monte le `docker.sock` de l'hôte, donc mes jobs `docker build`/`push` parlent au démon Docker de ma machine. Mon `.gitlab-ci.yml` n'a donc pas de `services: docker:dind`. »*

**« Comment le job fait `docker build` alors ? »**
- *« Le conteneur du job (image `docker:latest`) a la CLI docker, et il joint le démon Docker de l'hôte grâce au socket `/var/run/docker.sock` monté lors de l'enregistrement du runner (`--docker-volumes`). Conséquence concrète : l'image buildée est visible sur ma machine avec `docker image ls` (avec dind elle ne le serait pas — ce serait un autre démon). »*

**« Pourquoi `--password` et pas `--password-stdin` ? »**
- *« J'ai suivi la forme de la consigne (`--password "$ARM_CLIENT_SECRET"`). En vraie prod on préférerait `--password-stdin` pour éviter que le secret apparaisse dans la liste des process, mais `ARM_CLIENT_SECRET` est de toute façon une variable masquée dans GitLab (invisible dans les logs). »*

## Le `terraform.tfstate` — récap critique

C'est LE fichier le plus sensible de Terraform :
- Contient TOUS les outputs (URLs, IDs)
- Contient potentiellement des secrets en clair
- Évolue à chaque `apply` → doit être versionné quelque part (pas git !)

Dans le projet académique : on a `terraform.tfstate` en LOCAL sur ma machine, ignoré par `.gitignore`. Pour la défense Mac, je dois soit :
1. Le copier de mon PC Windows vers le Mac avant la défense
2. Ou faire un `terraform destroy` côté Windows + `terraform apply` côté Mac pour repartir from scratch

🎯 **À retenir** : *« Le tfstate est en local, ignoré de git. En production réelle on utiliserait un backend distant (Azure Storage Account avec lock) pour le partager et le sécuriser. Pour ce projet académique, local + .gitignore suffit. »*

## La révocation post-défense (à FAIRE !)

Après la défense, ces actions :

```bash
# 1. Récupérer l'objectId du SP
az ad sp list --display-name "sp-devops-66045" --query "[].id" -o tsv

# 2. Le supprimer
az ad sp delete --id <objectId>

# 3. Vérifier les variables GitLab — les supprimer aussi
# (Settings → CI/CD → Variables, supprimer ARM_*)

# 4. Destroy l'infra Azure
cd projet/terraform
terraform destroy

# 5. Vérifier qu'il ne reste rien
az resource list --query "[?contains(name, '66045')]" -o table
```

🎯 **À retenir** : *« Hygiène post-défense : supprimer le SP, vider les variables GitLab, détruire l'infra Azure pour libérer mes crédits Azure for Students. Sinon ça continue à compter sur mon quota même si je n'utilise plus le projet. »*

## Mini-récap secrets & Azure

| Question | Réponse |
|---|---|
| Combien de variables Azure dans GitLab CI ? | 5 : 4 ARM_* (auth) + ACR_NAME |
| À quoi sert le Service Principal ? | Authentifier le pipeline auprès d'Azure (Terraform + docker push + az restart) |
| Comment Terraform lit les ARM_* ? | Automatiquement via les variables d'env, pas besoin de les déclarer dans `providers.tf` |
| Pourquoi pas mettre les secrets dans `terraform.tfvars` ? | On pourrait mais c'est plus pratique de passer par les ARM_* env vars, surtout dans le pipeline |
| `terraform.tfstate` doit-il être commité ? | Non JAMAIS, il contient des données sensibles. Ignoré par .gitignore. En prod on utiliserait un backend distant |
| Que faire après la défense ? | `az ad sp delete`, supprimer vars GitLab, `terraform destroy` |
| Comment `az login --service-principal` marche-t-il sous le capot ? | OAuth2 : présente client_id+secret+tenant, Azure renvoie un token JWT valide 1h |
| Pourquoi rôle `Contributor` sur le SP ? | Minimal pour pouvoir créer toutes les ressources du projet. En prod on serait plus granulaire (moindre privilège) |
