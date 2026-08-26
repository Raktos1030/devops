output "flask_app_url" {
  description = "URL complète pour accéder au message de l'API Flask"
  value       = "https://${azurerm_linux_web_app.flask_app.default_hostname}/api/message"
}

output "spring_app_url" {
  description = "URL complète pour accéder à l'endpoint /proxy du service Spring Boot"
  value       = "https://${azurerm_linux_web_app.spring_app.default_hostname}/proxy"
}
