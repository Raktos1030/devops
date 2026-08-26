variable "location" {
  description = "Azure region"
  type        = string
  default     = "West Europe"
}
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "client_id" {
  description = "Azure client ID (App registration)"
  type        = string
}

variable "client_secret" {
  description = "Azure client secret"
  type        = string
  sensitive   = true
}

variable "tenant_id" {
  description = "Azure tenant ID"
  type        = string
}


variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-g63457"
}

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
  default     = "acr63457devops"
}

variable "identity_name" {
  description = "Name of the user-assigned managed identity"
  type        = string
  default     = "identity-g63457"
}

variable "service_plan_name" {
  description = "Name of the App Service plan"
  type        = string
  default     = "plan-g63457"
}

# Variables pour l'application Spring Boot (Java)
variable "web_app_spring_name" {
  description = "Name of the Web App for the Spring Boot application"
  type        = string
  default     = "spring-app-g63457"
}

variable "docker_image_springboot" {
  description = "Docker image name and tag for the Spring Boot application"
  type        = string
  default     = "spring-service:latest"
}

variable "web_app_springboot_port" {
  description = "Port on which the Spring Boot application listens"
  type        = string
  default     = "8080"
}

# Variables pour l'application Flask (Python)
variable "web_app_flask_name" {
  description = "Name of the Web App for the Flask application"
  type        = string
  default     = "flask-app-g63457"
}

variable "docker_image_flask" {
  description = "Docker image name and tag for the Flask application"
  type        = string
  default     = "flask-service:latest"
}

variable "web_app_flask_port" {
  description = "Port on which the Flask application listens"
  type        = string
  default     = "5000"
}
