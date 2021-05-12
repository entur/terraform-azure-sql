output "administrator_login" {
  value = azurerm_postgresql_server.main.administrator_login
}

output "administrator_login_password" {
  value     = azurerm_postgresql_server.main.administrator_login_password
  sensitive = true
}

output "application_login" {
  value = postgresql_role.roles["application"].name
}

output "application_login_password" {
  value     = postgresql_role.roles["application"].password
  sensitive = true
}

output "roles" {
  value = postgresql_role.roles
  sensitive = true
}

output custom_dns_configs {
  value = azurerm_private_endpoint.aks.custom_dns_configs
}

output "server_name" {
  value = azurerm_postgresql_server.main.name
}

output "server_fqdn" {
  value = azurerm_private_dns_a_record.privatelink.fqdn
}
