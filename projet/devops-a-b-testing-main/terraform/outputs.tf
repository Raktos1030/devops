output "spring_url" {
  value = "https://${azurerm_linux_web_app.spring_app.default_hostname}"
}

output "django_url" {
  value = "https://${azurerm_linux_web_app.django_app.default_hostname}"
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}
