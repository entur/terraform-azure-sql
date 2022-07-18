# PostgreSQL
provider "postgresql" {
  host            = azurerm_postgresql_flexible_server.main.fqdn
  username        = azurerm_postgresql_flexible_server.main.administrator_login
  password        = azurerm_postgresql_flexible_server.main.administrator_password
  sslmode         = "require"
  superuser       = false
  connect_timeout = 15
}