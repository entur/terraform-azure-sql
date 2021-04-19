provider "azurerm" {
  features {}
}

module "postgresql" {
  #source              = "github.com/entur/terraform-azure-sql//modules/postgresql?ref=v0.0.1"
  source              = "../../modules/postgresql"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  app_name                     = var.app_name
  environment                  = var.environment
  landing_zone                 = var.landing_zone
  kubernetes_secret_namespaces = [var.app_name]

  server_version = "11"
  sku_name       = "GP_Gen5_2"
  storage_mb     = 5120

  databases      = var.databases
  database_roles = var.database_roles
}
