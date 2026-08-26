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
