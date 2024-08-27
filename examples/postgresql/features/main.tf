module "postgresql" {
  source = "github.com/entur/terraform-azure-sql//modules/postgresql?ref=v1.0.0" # Releases: https://github.com/entur/terraform-azure-sql/releases (x-release-please-version)
  # source = "../../../modules/postgresql"

  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  app_name     = var.app_name
  environment  = var.environment
  landing_zone = var.landing_zone

  server_version = "11"
  sku_name       = "GP_Gen5_2"
  storage_mb     = 5120

  databases      = var.databases
  database_roles = var.database_roles
}

# The example below shows how to add an additional Kubernetes secret for an additional role created with this module

/*
# Note that you'll have to provide the role key under PGUSER and PGPASSWORD.
# Also note the convention used in PGUSER (role@servername), which is required 
# by Azure Database for PostgreSQL authentication.
*/

resource "kubernetes_secret" "example" {
  metadata {
    name      = "myapp-psql-credentials" # Secret name
    namespace = "mynamespace"            # Secret namespace
    labels    = var.tags
  }

  data = {
    PGUSER     = "${module.postgresql.roles["additional_role"].name}@${module.postgresql.server_name}" # Role key here
    PGPASSWORD = module.postgresql.roles["additional_role"].password                                   # Role key here
    PGHOST     = module.postgresql.server_fqdn
  }
}