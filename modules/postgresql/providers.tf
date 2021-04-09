# PostgreSQL
provider "postgresql" {
  host            = azurerm_private_dns_a_record.privatelink.fqdn
  username        = "${azurerm_postgresql_server.main.administrator_login}@${azurerm_postgresql_server.main.name}"
  password        = azurerm_postgresql_server.main.administrator_login_password
  sslmode         = "require"
  superuser       = false
  connect_timeout = 15
}