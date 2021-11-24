output "administrator_login" {
  value = azurerm_postgresql_flexible_server.main.administrator_login
}

output "administrator_password" {
  value     = azurerm_postgresql_flexible_server.main.administrator_password
  sensitive = true
}

output "application_login" {
  value = postgresql_role.roles["application"].name
}

output "application_login_password" {
  value     = postgresql_role.roles["application"].password
  sensitive = true
}

output "custom_dns_configs" {
  value = data.azurerm_private_dns_zone.dns_zone.id
}

output "roles" {
  value     = postgresql_role.roles
  sensitive = true
}

output "server_id" {
  value = azurerm_postgresql_flexible_server.main.id
}

output "server_name" {
  value = azurerm_postgresql_flexible_server.main.name
}

output "server_fqdn" {
  value = azurerm_postgresql_flexible_server.main.fqdn
}