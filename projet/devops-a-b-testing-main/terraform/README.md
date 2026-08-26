# Infrastructure Azure (Terraform)

Code Terraform decrivant l'infrastructure Azure pour heberger les deux versions du projet A/B Testing :
- Resource Group
- Azure Container Registry (ACR)
- App Service Plan (Linux B1)
- 2 App Services (Spring Boot port 8080, Django port 8000)

## Utilisation

    az login
    terraform init
    terraform plan
    terraform apply
    terraform destroy

## Note

Le deploiement reel a ete effectue sur AlwaysData suite a un probleme d'acces au compte Azure (MFA indisponible), possibilite autorisee par les consignes.
