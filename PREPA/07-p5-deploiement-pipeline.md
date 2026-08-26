# Partie 5 — Déploiement automatisé via le pipeline

## Ce que dit la consigne

> Intégrer le déploiement des deux applications dans le pipeline CI/CD :
> - Construire les images Docker
> - Déployer les services sur l'infrastructure Azure créée avec Terraform
> Tag `deploiement`.

## Ce qu'on a fait

Ajout dans `.gitlab-ci.yml` :
- Nouveau stage `deploy` avec 2 jobs `push-spring` et `push-django` (build des images Docker, push vers ACR)
- Nouveau stage `update` avec 2 jobs `update-spring` et `update-django` (restart des App Services pour qu'ils pullent les nouvelles images)

5 variables CI configurées dans GitLab UI :
- `ARM_CLIENT_ID`, `ARM_CLIENT_SECRET`, `ARM_TENANT_ID`, `ARM_SUBSCRIPTION_ID` (credentials du Service Principal Azure)
- `ACR_NAME` (le nom de l'ACR pour construire les URLs d'image)

Service Principal Azure créé : `sp-abtesting-cicd` avec rôle `Owner` sur la subscription.

Tag : **`deploiement`** (sur le commit `89b5b0e`)
Commits : `f735189` (push images) + `89b5b0e` (restart App Services)

## L'architecture du pipeline (état P5)

```
push sur main
     │
     ▼
┌─────────────┐  ┌─────────────┐
│ build-spring│  │ build-django│   stage : build (P3)
└──────┬──────┘  └──────┬──────┘
       └────────┬───────┘
                ▼
┌─────────────┐  ┌─────────────┐
│ test-spring │  │ test-django │   stage : test (P3)
└──────┬──────┘  └──────┬──────┘
       └────────┬───────┘
                ▼
┌─────────────┐  ┌─────────────┐
│ push-spring │  │ push-django │   stage : deploy (NEW P5)
└──────┬──────┘  └──────┬──────┘
       └────────┬───────┘
                ▼
┌─────────────┐  ┌─────────────┐
│update-spring│  │update-django│   stage : update (NEW P5)
└─────────────┘  └─────────────┘
```

8 jobs au total, 4 stages séquentiels.

## Les 5 variables CI — c'est quoi, à quoi ça sert

🔧 **Voir** : GitLab UI → Settings → CI/CD → Variables

| Variable | Source | Utilisée par |
|---|---|---|
| `ARM_CLIENT_ID` | `appId` du Service Principal | `docker login` (push-*), `az login` (update-*) |
| `ARM_CLIENT_SECRET` | `password` du SP (masked) | `docker login` (push-*), `az login` (update-*) |
| `ARM_TENANT_ID` | `tenant` du SP | `az login --tenant` (update-*) |
| `ARM_SUBSCRIPTION_ID` | ID de ma subscription Azure for Students | (pas utilisée explicitement dans le pipeline P5, mais réservée pour de futurs jobs Terraform en pipeline) |
| `ACR_NAME` | `acrabtesting66045` | Pour construire `$ACR_NAME.azurecr.io/...` (push-*) |

### Pourquoi les `ARM_*` portent ce préfixe exactement ?

C'est une convention du provider Terraform azurerm. Si tu mets ces variables d'env, le provider azurerm les utilise automatiquement pour s'authentifier. Donc même si on s'en sert ici dans le pipeline pour `docker login`/`az login`, le préfixe `ARM_*` permettrait aussi de faire tourner du Terraform dans le pipeline sans config supplémentaire (TD 09 page 15).

🎯 **À retenir** : *« 5 variables CI dans GitLab : 4 commencent par `ARM_*` (convention azurerm), 1 c'est `ACR_NAME`. Toutes en Masked sauf `ACR_NAME` (pas secret, c'est juste un nom). »*

## Le Service Principal Azure — c'est quoi

Un **Service Principal (SP)** c'est une identité d'application Azure (≠ identité utilisateur). Il a un `appId`, un `password`, et un rôle (chez nous : `Owner` sur la subscription).

Pourquoi un SP ? Le pipeline CI ne peut pas faire `az login` interactif (il n'y a personne pour valider dans un navigateur). Il a besoin d'identifiants statiques. Le SP fournit ces identifiants.

**Commande de création** :
```bash
az ad sp create-for-rbac \
  --name "sp-abtesting-cicd" \
  --role "Owner" \
  --scopes /subscriptions/<SUBSCRIPTION_ID>
```

Sortie JSON : `appId`, `password`, `tenant` → on copie ça dans les variables CI GitLab.

⚠️ **Pièges potentiels** :

**« Pourquoi le rôle Owner et pas un rôle plus restreint ? »**
- *« C'est l'approche du TD 09 page 15. En vrai pour le moindre privilège, on aurait pu donner `Contributor` (qui suffit pour créer/modifier les ressources) ou même un rôle custom avec juste les permissions nécessaires (`AcrPush` sur l'ACR, `Microsoft.Web/sites/restart/action` sur les App Services). Owner c'est large mais ça marche, et c'est ce que le cours montre. »*

**« Pourquoi pas utiliser Managed Identity comme pour les App Services ? »**
- *« Managed Identity ne fonctionne que pour des ressources qui tournent SUR Azure. Le pipeline GitLab tourne sur mon runner local (chez moi, à Bruxelles), pas sur Azure. Donc Managed Identity n'est pas possible, il faut un SP avec credentials. »*

**« Si tu compromets le SP, qu'est-ce que tu fais ? »**
- *« Je révoque les credentials avec `az ad sp credential reset` ou je supprime carrément le SP avec `az ad sp delete`. Puis je crée un nouveau SP et je mets à jour les variables CI. »*

## Décortique des jobs `push-spring` / `push-django`

🔧 **Code** : `projet/.gitlab-ci.yml` (section `deploy`)

```yaml
push-spring:
  stage: deploy
  image: docker:latest
  script:
    - docker login "$ACR_NAME.azurecr.io" -u "$ARM_CLIENT_ID" --password "$ARM_CLIENT_SECRET"
    - docker build -t "$ACR_NAME.azurecr.io/spring-boot:latest" ./spring-boot
    - docker push "$ACR_NAME.azurecr.io/spring-boot:latest"

push-django:
  stage: deploy
  image: docker:latest
  script:
    - docker login "$ACR_NAME.azurecr.io" -u "$ARM_CLIENT_ID" --password "$ARM_CLIENT_SECRET"
    - docker build -t "$ACR_NAME.azurecr.io/django:latest" ./django
    - docker push "$ACR_NAME.azurecr.io/django:latest"
```

### Ligne par ligne

| Ligne | À dire |
|---|---|
| `image: docker:latest` | « Image officielle docker qui contient le CLI docker. Le job tourne dans un conteneur de cette image. » |
| `docker login "$ACR_NAME.azurecr.io" -u "$ARM_CLIENT_ID" --password "$ARM_CLIENT_SECRET"` | « S'authentifie au registry Azure avec les credentials du SP. Format URL d'un ACR : `<acrname>.azurecr.io`. C'est la commande exacte recommandée par la consigne dans la note de Partie 5. » |
| `docker build -t "$ACR_NAME.azurecr.io/spring-boot:latest" ./spring-boot` | « Build l'image depuis le dossier `spring-boot/`, en la taguant DIRECTEMENT avec l'URL ACR cible. Comme ça, le `docker push` saura où envoyer. » |
| `docker push "$ACR_NAME.azurecr.io/spring-boot:latest"` | « Pousse l'image vers ACR. » |

### 🎯 À retenir

*« Le job de push fait 3 étapes : login ACR avec les credentials du SP, build de l'image en la taguant avec l'URL ACR, puis push. Le truc subtil c'est que le tag du `docker build` ET la cible du `docker push` doivent être identiques, sinon `docker push` ne saura pas quelle image envoyer. »*

### Pourquoi ça marche techniquement ? (le `--docker-volumes`)

Le runner a été enregistré avec `--docker-volumes "/var/run/docker.sock:/var/run/docker.sock"`. Ça monte le socket Docker hôte dans le conteneur du job. Quand le job lance `docker build`, il communique avec le démon Docker de MA machine. Donc le build et le push utilisent le Docker hôte, pas un Docker dans le conteneur. C'est l'approche « accès au démon hôte » du TD 07 page 21.

⚠️ **Piège potentiel** : *« comment le conteneur du job peut faire `docker build` ? Y'a Docker dedans ? »* — *« Non. Le démon Docker du host est partagé via le socket. Le CLI docker dans `docker:latest` envoie ses commandes au démon hôte. C'est documenté TD 07 p.21. »*

## Décortique des jobs `update-spring` / `update-django`

🔧 **Code** : `projet/.gitlab-ci.yml` (section `update`)

```yaml
update-spring:
  stage: update
  image: mcr.microsoft.com/azure-cli:latest
  script:
    - az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
    - az webapp restart --name app-spring-66045 --resource-group rg-abtesting-66045

update-django:
  stage: update
  image: mcr.microsoft.com/azure-cli:latest
  script:
    - az login --service-principal -u "$ARM_CLIENT_ID" -p "$ARM_CLIENT_SECRET" --tenant "$ARM_TENANT_ID"
    - az webapp restart --name app-django-66045 --resource-group rg-abtesting-66045
```

### Ligne par ligne

| Ligne | À dire |
|---|---|
| `image: mcr.microsoft.com/azure-cli:latest` | « Image officielle Microsoft qui contient Azure CLI (`az`). MCR = Microsoft Container Registry. » |
| `az login --service-principal ...` | « Login à Azure en mode non-interactif via les credentials du SP. Le `--service-principal` indique le mode SP, les flags `-u/-p/--tenant` fournissent les 3 valeurs. » |
| `az webapp restart --name X --resource-group Y` | « Redémarre l'App Service nommé X dans le RG Y. Le restart force l'App Service à re-pull son image depuis l'ACR. Comme on vient de pousser une nouvelle version dans le stage `deploy`, c'est cette nouvelle image qui sera prise. » |

### 🎯 À retenir

*« Le job d'update fait `az login` avec le SP puis `az webapp restart` sur l'App Service. Le restart force le re-pull de l'image depuis l'ACR, donc l'app tourne avec la nouvelle version. »*

### ⚠️ Pièges potentiels

**« Pourquoi un restart suffit ? L'App Service détecte pas tout seul qu'il y a une nouvelle image ? »**
- *« Par défaut non. L'App Service pull l'image au démarrage seulement. Pour le re-pull automatique on pourrait configurer un webhook ACR → App Service, mais le restart manuel via le pipeline est plus simple et explicite. »*

**« Les noms `app-spring-66045` et `rg-abtesting-66045` sont en dur. C'est pas sale ? »**
- *« Idéalement on les passerait via des variables CI. Pour rester simple et lisible je les ai mis en dur, mais ça matche les valeurs par défaut des variables Terraform donc c'est cohérent. Si on changeait les noms côté Terraform il faudrait mettre à jour ici aussi. »*

**« L'ordre `deploy` puis `update` est-il vraiment nécessaire ? »**
- *« Oui. Si `update` tournait AVANT `deploy`, on restart les App Services avant que la nouvelle image soit dans l'ACR → ils repullent l'ancienne, ce qui ne sert à rien. L'ordre des stages garantit que `update` ne tourne que si `deploy` a réussi. »*

## Décortique : ce qui a été ajouté au `.gitlab-ci.yml`

🔧 **Voir** : `projet/.gitlab-ci.yml`

Changements P5 (par rapport à P3) :
- Ajout de 2 stages : `deploy` et `update` dans le bloc `stages:`
- Ajout des 4 jobs `push-spring`, `push-django`, `update-spring`, `update-django`

Structure finale :
```yaml
stages:
  - build      # P3
  - test       # P3
  - deploy     # P5 - push images vers ACR
  - update     # P5 - restart App Services
```

## Mini-récap pour P5

| Question | Réponse |
|---|---|
| Combien de stages dans le pipeline après P5 ? | 4 : build, test, deploy, update |
| Combien de jobs au total ? | 8 (4 P3 + 4 P5) |
| Quelle image pour les jobs push-* ? | `docker:latest` (contient CLI docker) |
| Quelle image pour les jobs update-* ? | `mcr.microsoft.com/azure-cli:latest` (contient `az`) |
| C'est quoi un Service Principal ? | Identité d'application Azure utilisée pour auth machine-to-machine (pipeline → Azure) |
| Pourquoi rôle Owner sur le SP ? | Approche du TD 09 p.15, large mais simple. Idéalement Contributor ou custom |
| Quelles variables CI ? | 5 : ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID, ACR_NAME |
| Pourquoi préfixe `ARM_*` ? | Convention du provider Terraform azurerm, pour que ces vars soient auto-détectées si on fait du Terraform en pipeline |
| Pourquoi le SP plutôt que Managed Identity ? | MI ne marche que pour ressources sur Azure. Le runner GitLab est local (chez moi), donc SP nécessaire |
| Comment `docker build` peut tourner dans le job ? | Volume `/var/run/docker.sock` partagé entre le conteneur runner et le démon Docker hôte (TD 07 p.21) |
| Pourquoi restart l'App Service après push d'image ? | L'App Service pull l'image au démarrage uniquement. Restart force le re-pull → nouvelle version active |
| Pourquoi stage `update` après `deploy` ? | Sinon on restart avant que l'image soit dans l'ACR → on relance l'ancienne |
