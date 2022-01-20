locals {
  # If kubernetes_create_secret == false, set var.kubernetes_namespaces as empty list.
  # If kubernetes_create_secret == true, use var.kubernetes_namespaces if set.
  # If kubernetes_create_secret == true but var.kubernetes_namespaces is not set (default), set it to a single entry list containing var.app_name.
  kubernetes_namespaces = var.kubernetes_create_secret == false ? [] : length(var.kubernetes_namespaces) > 0 ? var.kubernetes_namespaces : [var.app_name]

  kubernetes_secret_name = var.kubernetes_secret_name != null ? var.kubernetes_secret_name : "${var.app_name}-psql-credentials"
  postgresql_server_name = var.postgresql_server_name != null ? var.postgresql_server_name : "psql-${var.app_name}-${var.environment}"

  grants_t = flatten(
    [for role in var.database_roles :
      [for count, grant in role.grants :
        {
          index : "${role.name}_${count}"
          role : role.name
          database : grant.database
          schema : grant.schema
          object_type : grant.object_type
          privileges : grant.privileges
        }
      ]
    ]
  )

  grants = {
    for grant in local.grants_t : grant.index => grant
  }
}

# Fetch private DNS zone
data "azurerm_private_dns_zone" "dns_zone" {
  name                = "privatelink.postgres.database.azure.com"
  resource_group_name = "${var.network_resource_group_prefix}-${var.landing_zone}"
}

# Fetch subnet designated to PostgreSQL flexible server connections
data "azurerm_subnet" "psqlflex" {
  name                 = "${var.psql_connections_subnet_name_prefix}-${var.landing_zone}"
  virtual_network_name = "${var.vnet_name_prefix}-${var.landing_zone}"
  resource_group_name  = "${var.network_resource_group_prefix}-${var.landing_zone}"
}

# Generate admin role password
resource "random_password" "admin" {
  length           = 64
  special          = true
  override_special = "_%@"
}

# Provision the PostgreSQL flexible server instance
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = local.postgresql_server_name
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = var.server_version
  delegated_subnet_id    = data.azurerm_subnet.psqlflex.id
  private_dns_zone_id    = data.azurerm_private_dns_zone.dns_zone.id
  administrator_login    = var.administrator_login
  administrator_password = random_password.admin.result
  backup_retention_days  = var.backup_retention_days
  storage_mb             = var.storage_mb
  sku_name               = var.sku_name
  tags                   = var.tags
  lifecycle {
    prevent_destroy = true
  }
}

# Generate role passwords
resource "random_password" "roles" {
  for_each         = var.database_roles
  length           = 64
  special          = true
  override_special = "_%@"
}

# Provision databases
resource "azurerm_postgresql_flexible_server_database" "databases" {
  for_each  = { for db in var.databases : db => db }
  name      = each.value
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = var.db_charset
  collation = var.db_collation
  lifecycle {
    prevent_destroy = true
  }
}

# Provision any custom configuration
resource "azurerm_postgresql_flexible_server_configuration" "configs" {
  for_each  = var.server_configurations
  server_id = azurerm_postgresql_flexible_server.main.id
  name      = each.key
  value     = each.value
}

# Provision db credentials and connection information in Kubernetes cluster
resource "kubernetes_secret" "db_credentials" {
  for_each = { for ns in local.kubernetes_namespaces : ns => ns }

  metadata {
    name      = local.kubernetes_secret_name
    namespace = each.value
    labels    = var.tags
  }

  data = {
    PGUSER     = postgresql_role.roles["application"].name
    PGPASSWORD = postgresql_role.roles["application"].password
    PGHOST     = azurerm_postgresql_flexible_server.main.fqdn
  }
}

# Create roles
resource "postgresql_role" "roles" {
  for_each            = var.database_roles
  name                = each.value.name
  replication         = try(each.value.replication, false)
  login               = true
  superuser           = false
  create_database     = false
  create_role         = false
  inherit             = true
  password            = each.value.password_override != null ? each.value.password_override : random_password.roles[each.key].result
  skip_reassign_owned = true

  depends_on = [
    azurerm_postgresql_flexible_server.main,
  ]
}

# Create schemas
resource "postgresql_schema" "schemas" {
  for_each      = local.grants
  name          = each.value.schema
  database      = each.value.database
  drop_cascade  = var.drop_cascade
  if_not_exists = true

  depends_on = [
    azurerm_postgresql_flexible_server.main,
    azurerm_postgresql_flexible_server_database.databases
  ]

  lifecycle {
    prevent_destroy = true
  }
}

# Create grants for roles
resource "postgresql_grant" "roles" {
  for_each    = local.grants
  database    = each.value.database
  role        = each.value.role
  schema      = each.value.schema
  object_type = each.value.object_type
  privileges  = each.value.privileges

  depends_on = [
    azurerm_postgresql_flexible_server.main,
    azurerm_postgresql_flexible_server_database.databases,
    postgresql_role.roles,
    postgresql_schema.schemas
  ]
}
