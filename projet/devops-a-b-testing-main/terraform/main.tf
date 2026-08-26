# Infrastructure Azure pour A/B Testing
# Note : deploiement effectif sur AlwaysData (acces Azure indisponible, autorise par les consignes)

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "rg-devops-${var.matricule}"
  location = var.location
}

resource "azurerm_container_registry" "acr" {
  name                = "acrdevops${var.matricule}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true
}

resource "azurerm_service_plan" "main" {
  name                = "asp-devops-${var.matricule}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "spring_app" {
  name                = "spring-ab-${var.matricule}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id
  site_config {
    application_stack {
      docker_image_name   = "spring-ab:latest"
      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
    }
  }
  app_settings = {
    WEBSITES_PORT = "8080"
  }
}

resource "azurerm_linux_web_app" "django_app" {
  name                = "django-ab-${var.matricule}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id
  site_config {
    application_stack {
      docker_image_name   = "django-ab:latest"
      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
    }
  }
  app_settings = {
    WEBSITES_PORT = "8000"
  }
}
