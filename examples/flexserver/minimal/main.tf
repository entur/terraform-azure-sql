module "postgresql-flexserver" {
  source = "github.com/entur/terraform-azure-sql//modules/postgresql-flex?ref=v0.0.6" # Releases: https://github.com/entur/terraform-azure-sql/releases

  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  app_name     = var.app_name
  environment  = var.environment
  landing_zone = var.landing_zone

  server_version = "12"
  sku_name       = "GP_Standard_D4s_v3"
  storage_mb     = 32768

  databases      = var.databases
  database_roles = var.database_roles
}