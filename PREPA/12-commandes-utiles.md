# Commandes utiles — cheat sheet pour la défense

Toutes les commandes que je dois pouvoir taper **sans réfléchir** pendant la défense. Catégorisées par outil. Le but : si le prof dit *« montre-moi tes conteneurs qui tournent »*, je tape `docker ps` direct sans hésiter 10 sec.

## Docker — niveau base

```bash
# Voir les images locales
docker images

# Voir les conteneurs qui tournent
docker ps

# Voir TOUS les conteneurs (même arrêtés)
docker ps -a

# Build une image depuis un Dockerfile
docker build -t mon-image:tag ./chemin

# Lancer un conteneur
docker run -p 8080:8080 --name mon-conteneur mon-image:tag

# Logs d'un conteneur
docker logs <container-id>

# Tail des logs (suivre en live)
docker logs -f <container-id>

# Entrer dans un conteneur (shell)
docker exec -it <container-id> sh

# Stopper un conteneur
docker stop <container-id>

# Supprimer un conteneur
docker rm <container-id>

# Supprimer une image
docker rmi <image-id>

# Inspecter une image (LABELs, env, etc.)
docker inspect <image-id>

# Voir l'auteur d'une image (le LABEL author)
docker inspect <image-id> | grep -i author
```

## Docker Compose

```bash
# Lancer tous les services en avant-plan (logs visibles)
docker-compose up

# Lancer en arrière-plan (détaché)
docker-compose up -d

# Rebuilder les images avant de lancer (utile après modif Dockerfile)
docker-compose up --build

# Voir les logs des services
docker-compose logs

# Voir les logs d'UN service
docker-compose logs nginx

# Stopper tous les services
docker-compose down

# Stopper + supprimer les volumes (clean total)
docker-compose down -v

# Rebuild un seul service
docker-compose build nginx

# Forcer le restart d'un service
docker-compose restart nginx
```

🎯 **À retenir** : *« `docker-compose up --build -d` rebuild et lance en background. `docker-compose down` arrête. C'est mon flux principal en local. »*

## Terraform

```bash
# Initialiser (à faire 1 fois après clone, et après changement de provider)
terraform init

# Voir ce qui SERA fait (dry run)
terraform plan

# Appliquer (création/modif/suppression des ressources)
terraform apply

# Appliquer SANS prompt de confirmation
terraform apply -auto-approve

# Détruire toute l'infra
terraform destroy

# Lister les ressources actuellement managées
terraform state list

# Voir l'état actuel d'une ressource
terraform state show azurerm_resource_group.rg

# Voir les outputs
terraform output

# Voir un output spécifique
terraform output spring_app_url

# Formater les fichiers .tf (style standard)
terraform fmt

# Valider la syntaxe
terraform validate
```

🎯 **À retenir** : *« Cycle complet : `terraform init` (1x), puis `plan` (vérifier) → `apply` (créer) → ... → `destroy` (cleanup). `state list` me confirme ce qui est UP. »*

## Azure CLI (az)

```bash
# Se logger interactivement (ouvre un browser)
az login

# Se logger via Service Principal (pour scripts)
az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID

# Voir le compte actif
az account show

# Lister mes souscriptions
az account list -o table

# Switcher de souscription
az account set --subscription <subscription-id>

# Lister les resource groups
az group list -o table

# Voir tout dans un RG
az resource list --resource-group rg-abtesting-66045 -o table

# Voir mes App Services
az webapp list -o table

# Restart une App Service
az webapp restart --name app-spring-66045 --resource-group rg-abtesting-66045

# Voir les logs d'une App Service (live)
az webapp log tail --name app-spring-66045 --resource-group rg-abtesting-66045

# Voir l'URL d'une App Service
az webapp show --name app-spring-66045 --resource-group rg-abtesting-66045 --query defaultHostName

# Lister les ACR
az acr list -o table

# Lister les images dans un ACR
az acr repository list --name acrabtesting66045 -o table

# Lister les tags d'une image
az acr repository show-tags --name acrabtesting66045 --repository spring-boot

# Voir les régions autorisées (pour Azure for Students)
az policy assignment list --query "[].displayName"

# Voir mon Service Principal
az ad sp list --display-name "sp-devops-66045"

# Supprimer le SP (post-défense)
az ad sp delete --id <appId>
```

🎯 **À retenir** : *« `az login` puis `az account show` pour vérifier le compte. `az webapp restart` c'est ce que fait mon pipeline. `az resource list` me montre tout ce qui existe dans mon RG. »*

## GitLab Runner (utile si le prof gratte)

```bash
# Voir si le runner tourne
docker ps | grep gitlab-runner

# Logs du runner
docker logs gitlab-runner

# Suivre les logs live
docker logs -f gitlab-runner

# Restart le runner
docker restart gitlab-runner

# Voir la config
cat ~/gitlab-runner/config/config.toml
# (sur Mac/Linux ; sur Windows c'est %USERPROFILE%\gitlab-runner\config\config.toml)

# Lister les runners enregistrés
docker exec gitlab-runner gitlab-runner list

# Désinscrire un runner
docker exec gitlab-runner gitlab-runner unregister --token <token>
```

## Git (commandes utiles pour la démo)

```bash
# Voir l'historique des commits
git log --oneline

# Voir les tags
git tag

# Voir un commit précis
git show <hash>

# Voir le contenu à un tag donné
git checkout <tag>
# (et après : `git checkout main` pour revenir)

# Pousser un tag
git tag mon-tag
git push origin mon-tag

# Voir les branches
git branch -a

# Différences entre main et un commit
git diff main..<hash>

# Voir QUI a touché quelle ligne
git blame fichier.py
```

🎯 **À retenir** : *« `git log --oneline` me sort mes ~10 commits en une vue. `git tag` me montre mes 6 tags. `git show <hash>` me sort le diff d'un commit. »*

## Démos à pouvoir lancer en moins de 60 secondes

### Démo 1 — A/B testing local

```bash
cd projet
docker-compose up -d --build
# Attendre ~30 sec que les apps démarrent
curl http://localhost:80/test   # → Spring
curl http://localhost:80/test   # → Django
curl http://localhost:80/test   # → Spring (round-robin)
```

### Démo 2 — Vérifier les images dans l'ACR

```bash
az acr repository list --name acrabtesting66045 -o table
# → doit montrer spring-boot et django
```

### Démo 3 — Vérifier l'infra Azure UP

```bash
terraform state list
# → doit montrer 7 ressources
az resource list --resource-group rg-abtesting-66045 -o table
# → doit montrer rg, acr, identity, service plan, 2 webapps
```

### Démo 4 — Modifier un truc en live (Question 3 du prof)

Si le prof demande *« change le port Django de 8000 à 8050 »* :
```bash
# 1. Modifier docker-compose.yml : ports: - "8050:8050"
# 2. Modifier django/Dockerfile : CMD ... 0.0.0.0:8050 et EXPOSE 8050
# 3. Modifier nginx/nginx.conf : server django:8050;

docker-compose down
docker-compose up -d --build
curl http://localhost:80/test   # → doit toujours alterner A/B
```

🎯 **À retenir** : *« Pour les modifs en live, faut connaître les 3 endroits à toucher : docker-compose.yml, Dockerfile concerné, nginx.conf. Si j'en oublie un, ça pète. »*

## Raccourcis VS Code à connaître pour la démo

| Raccourci | Action |
|---|---|
| `Ctrl+P` | Quick open d'un fichier par nom |
| `Ctrl+Shift+F` | Chercher dans tout le projet |
| `Ctrl+B` | Toggle sidebar (gagner de la place quand on partage l'écran) |
| `Ctrl+\`` | Toggle terminal intégré |
| `Ctrl+/` | Commenter/décommenter la ligne (pratique Question 2 — commenter EXPOSE) |
| `F2` | Renommer une variable / un symbole partout |

🎯 **À retenir** : *« Pendant la défense j'ouvre VS Code avec le terminal en bas. `Ctrl+P` → tape "dockerfile" → choisir → expliquer. Ça doit être ULTRA fluide. »*

## Si quelque chose tombe en marche

### Plan B : Docker plante

```bash
# Redémarrer Docker Desktop (Windows/Mac : juste relancer l'app)
# Puis :
docker info  # → si OK, le démon répond
docker ps    # → liste vide ou conteneurs précédents
```

### Plan B : Azure session expirée

```bash
az login   # → ouvre le browser, login à mon compte ESI Azure for Students
az account show   # → confirme
```

### Plan B : Terraform state cassé

```bash
# Si le state Terraform local ne reflète pas la réalité Azure :
terraform refresh   # → resync depuis Azure
# Si ça suffit pas et qu'on veut repartir à zéro :
terraform destroy
# Puis :
terraform apply
```

### Plan B : Pipeline GitLab échoue

1. Aller sur git.esi-bru.be → Build → Pipelines
2. Cliquer sur le pipeline rouge → cliquer sur le job rouge
3. Lire les logs → identifier l'erreur
4. Si c'est un timeout réseau ou docker.sock : juste retry le job (icône ↻)
5. Si c'est `az` qui dit "subscription not found" → vérifier les variables CI

🎯 **À retenir** : *« En cas de pépin pendant la démo, ne pas paniquer. La majorité des soucis se règle avec un `docker restart`, un `az login`, ou un retry du job pipeline. »*

## Quick-glance pour l'oral

Si je dois me souvenir d'une seule commande par catégorie :

- Docker → `docker ps`
- Compose → `docker-compose up -d --build`
- Terraform → `terraform state list`
- Azure → `az resource list --resource-group rg-abtesting-66045 -o table`
- Git → `git log --oneline`

5 commandes pour montrer que tout est en ordre.
