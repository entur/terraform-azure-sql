locals {
  postgresql_server_name = var.postgresql_server_name != null ? var.postgresql_server_name : "psql-${var.app_name}-${var.environment}"
  kubernetes_namespace   = var.kubernetes_namespace != null ? var.kubernetes_namespace : var.app_name
  kubernetes_secret_name = var.kubernetes_secret_name != null ? var.kubernetes_secret_name : "${var.app_name}-psql-credentials"

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

# Provision the PostgreSQL server instance
resource "azurerm_postgresql_server" "main" {
  name                             = local.postgresql_server_name
  location                         = var.location
  resource_group_name              = var.resource_group_name
  sku_name                         = var.sku_name
  storage_mb                       = var.storage_mb
  backup_retention_days            = var.backup_retention_days
  geo_redundant_backup_enabled     = var.geo_redundant_backup_enabled
  auto_grow_enabled                = var.auto_grow_enabled
  administrator_login              = var.administrator_login
  administrator_login_password     = random_password.admin.result
  version                          = var.server_version
  ssl_enforcement_enabled          = true
  ssl_minimal_tls_version_enforced = "TLS1_2"
  public_network_access_enabled    = var.public_network_access_enabled
  tags                             = var.tags

  lifecycle {
    prevent_destroy = true
  }
}

# Generate admin role password
resource "random_password" "admin" {
  length           = 64
  special          = true
  override_special = "_%@"
}

# Generate role passwords
resource "random_password" "roles" {
  for_each         = var.database_roles
  length           = 64
  special          = true
  override_special = "_%@"
}

# Provision databases
resource "azurerm_postgresql_database" "databases" {
  for_each            = { for db in var.databases: db => db }
  name                = each.value
  resource_group_name = azurerm_postgresql_server.main.resource_group_name
  server_name         = azurerm_postgresql_server.main.name
  charset             = var.db_charset
  collation           = var.db_collation

  lifecycle {
    prevent_destroy = true
  }
}

# Provision any custom configuration
resource "azurerm_postgresql_configuration" "configs" {
  for_each            = var.server_configurations
  resource_group_name = azurerm_postgresql_server.main.resource_group_name
  server_name         = azurerm_postgresql_server.main.name
  name                = each.key
  value               = each.value
}

# Network - private endpoint connection
data "azurerm_subnet" "aks" {
  name                 = "${var.aks_connections_subnet_name_prefix}-${var.landing_zone}"
  virtual_network_name = "${var.vnet_name_prefix}-${var.landing_zone}"
  resource_group_name  = "${var.network_resource_group_prefix}-${var.landing_zone}"
}

# Establish a private endpoint connection
resource "azurerm_private_endpoint" "aks" {
  name                = "pe-aks-${azurerm_postgresql_server.main.name}"
  location            = var.location
  resource_group_name = data.azurerm_subnet.aks.resource_group_name
  subnet_id           = data.azurerm_subnet.aks.id

  private_service_connection {
    name                           = "pec-aks-${azurerm_postgresql_server.main.name}"
    private_connection_resource_id = azurerm_postgresql_server.main.id
    subresource_names              = ["postgresqlServer"]
    is_manual_connection           = false
  }
}

# Create a private DNS record for use with private endpoint connection
resource "azurerm_private_dns_a_record" "privatelink" {
  name                = azurerm_postgresql_server.main.name
  resource_group_name = data.azurerm_subnet.aks.resource_group_name
  zone_name           = "privatelink.postgres.database.azure.com"
  ttl                 = 60
  records             = azurerm_private_endpoint.aks.custom_dns_configs[0].ip_addresses
}

# Provision db credentials and connection information in Kubernetes cluster
resource "kubernetes_secret" "db_credentials" {
  count = var.kubernetes_create_secret == true ? 1 : 0
  metadata {
    name      = local.kubernetes_secret_name
    namespace = local.kubernetes_namespace
    labels    = var.tags
  }

  data = {
    PGUSER     = "${postgresql_role.roles["application"].name}@${azurerm_postgresql_server.main.name}"
    PGPASSWORD = postgresql_role.roles["application"].password
    PGHOST     = azurerm_private_dns_a_record.privatelink.fqdn
  }
}

resource "kubernetes_secret" "share_db_credentials" {
  for_each            = { for ns in var.share_to_kubernetes_namespaces: ns => ns }
  
  metadata {
    name      = local.kubernetes_secret_name
    namespace = each.value
    labels    = var.tags
  }

  data = {
    PGUSER     = "${postgresql_role.roles["application"].name}@${azurerm_postgresql_server.main.name}"
    PGPASSWORD = postgresql_role.roles["application"].password
    PGHOST     = azurerm_private_dns_a_record.privatelink.fqdn
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
    azurerm_postgresql_server.main
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
    azurerm_postgresql_server.main,
    azurerm_postgresql_database.databases
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
    azurerm_postgresql_server.main,
    azurerm_postgresql_database.databases,
    postgresql_role.roles,
    postgresql_schema.schemas
  ]
}
