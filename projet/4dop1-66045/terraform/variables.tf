variable "location" {
  description = "Azure region"
  type        = string
  default     = "francecentral"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-abtesting-66045"
}

variable "acr_name" {
  description = "Name of the Azure Container Registry"
  type        = string
  default     = "acrabtesting66045"
}

variable "identity_name" {
  description = "Name of the user-assigned managed identity"
  type        = string
  default     = "id-abtesting"
}

variable "service_plan_name" {
  description = "Name of the App Service plan"
  type        = string
  default     = "asp-abtesting"
}

variable "spring_app_name" {
  description = "Name of the Spring Boot web app"
  type        = string
  default     = "app-spring-66045"
}

variable "django_app_name" {
  description = "Name of the Django web app"
  type        = string
  default     = "app-django-66045"
}

variable "spring_image" {
  description = "Docker image tag for the Spring Boot app"
  type        = string
  default     = "spring-boot:latest"
}

variable "django_image" {
  description = "Docker image tag for the Django app"
  type        = string
  default     = "django:latest"
}
