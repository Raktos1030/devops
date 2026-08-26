# Projet DevOps – Service Java & Flask

Ce projet contient deux services conteneurisés déployés sur Azure :

* `service-java-main` : application Spring Boot
* `service-python-main` : application Flask

## Fonctionnalités

| Service | Port exposé | Fonction principale                               |
| ------- | ----------- | ------------------------------------------------- |
| Flask   | `5001`      | Retourne `"Hello from Flask!"` via `/api/message` |
| Java    | `8080`      | Application Spring Boot                           |

> ℹ️ Le port `5000` est utilisé par macOS pour `AirPlay Receiver`. On utilise donc le port `5001` pour Flask.

---

## 1. Prérequis

* Docker et Docker Compose
* Azure CLI connecté (`az login`)
* Terraform ≥ 1.5
* Avoir créé une **identité managée** et un **Azure Container Registry (ACR)**

---

## 2. Build & push des images Docker

### Pour le service Flask (Python)

```bash
cd service-python-main

docker build --platform linux/amd64 -t flask-service:latest .
docker tag flask-service:latest acr63457devops.azurecr.io/flask-service:latest
docker push acr63457devops.azurecr.io/flask-service:latest
```

### Pour le service Spring Boot (Java)

```bash
cd service-java-main

docker build --platform linux/amd64 -t spring-service:latest .
docker tag spring-service:latest acr63457devops.azurecr.io/spring-service:latest
docker push acr63457devops.azurecr.io/spring-service:latest
```

---

## 3. Déploiement avec Terraform

### 3.1. Initialisation

```bash
terraform init
```

### 3.2. Planification (aperçu sans modification)

```bash
terraform plan
```

### 3.3. Application (création des ressources)

```bash
terraform apply
```

> Variables sensibles comme `client_id`, `client_secret`, `tenant_id`, `subscription_id` doivent être déclarées dans un fichier `terraform.tfvars` (non commit).

---

## 4. Nettoyage (pour éviter toute facturation)

```bash
terraform destroy
```

---

## 5. Accès aux applications

Les URL finales sont affichées après le `terraform apply`, via les outputs définis dans `outputs.tf` :

```bash
Outputs:

flask_app_url      = https://flask-app-g63457.azurewebsites.net/api/message
springboot_app_url = https://spring-app-g63457.azurewebsites.net/proxy
```

