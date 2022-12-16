# Terraform module for Azure Database for PostgreSQL flexible server

Creates a managed PostgreSQL flexible server instance on Azure.

* Provisions a new PostgreSQL flexible server instance
* Configures private network access via VNET integration
* Creates databases, schemas and roles with grants
* Provisions a Kubernetes secret containing application role credentials

## Prerequisites
* A preprovisioned landing zone subnet and private DNS zone (in Entur, these have been provided for you)

## Getting started
For example configurations, see the [included examples](../../examples).

### Adding databases
To add databases, supply a list of database names. Charset and collation settings can be overridden using variables described in the list of [inputs](#inputs).

#### Example
```
variable "databases" {
  type        = list(string)
  default     = ["mydatabase", "anotherdatabase"]
}
```

### Adding roles and grants
To add a role, supply a map containing role names and associated grants.

* Grants can only be applied to existing databases. Make sure you have added them to the [list of databases](#adding-databases).
* The `application` key entry is for the role used by your application, and is required.
* Always make conscious decisions on what privileges you grant roles. The examples included are for illustration only.

For grants, the following [object types](https://registry.terraform.io/providers/cyrilgdn/postgresql/latest/docs/resources/postgresql_grant) are allowed: `database`, `schema`, `table`, `sequence` or `function`.

Passwords are auto-generated. Database schemas that don't exist will be created automatically.

#### Example
```
variable "database_roles" {
  type    = map
  default = {
    application = {
      name              = "appuser"
      password_override = null # Leave empty
      replication       = false
      roles             = ["pg_monitor"]
      grants = [
        {
          database    = "mydatabase"
          schema      = "public"
          object_type = "database"
          privileges  = ["CONNECT", "TEMPORARY"]
        },
        {
          database    = "mydatabase"
          schema      = "public"
          object_type = "schema"
          privileges  = ["USAGE", "CREATE"]
        }
      ]
    }
  }
}
```

### PostgreSQL configuration parameters
Custom configuration parameters can be applied by supplying a map of strings.

#### Example
```
variable "server_configurations" {
  type        = map(string)
  default     = {
    "autovacuum"         = "on"
    "autovacuum_naptime" = "15"
  }
}
```

## Networking
### Connecting from an application
Application-to-server communication use private network access via VNET integration, meaning it will communicate privately on a dedicated link from the Kubernetes cluster to the PostgreSQL server instance. Connection information (host) and role credentials (username and password) are provided in the [Kubernetes secret](#example-kubernetes-secret). 

When mounting the entire Kubernetes secret to your Kubernetes deployment, an example Spring Boot `application.yml` configuration block could look like this:

```
spring:
  datasource:
    url: jdbc:postgresql://${PGHOST}:5432/mydatabase
    username: ${PGUSER}
    password: ${PGPASSWORD}
```

The application container can communicate directly with the server instance using TLS, and it does not require a sidecar.

### Connecting from a local machine
Public network access is denied, meaning the only way to connect to the database is through the private endpoint.

For instructions on how to connect securely from a local machine, please see internal Entur instructions.

### Example Kubernetes secret
By default, secret names are prefixed with the application name specified in `var.app_name`, i.e. `<appname>-psql-credentials`. 

If `var.app_name` = `petshop`, it would produce a secret named `petshop-psql-credentials`.
```
apiVersion: v1
data:
  PGHOST: ...
  PGPASSWORD: ...
  PGUSER: ...
kind: Secret
[...]
```

## Troubleshooting

### Administrator login password changed
The server administrator password is generated and managed by Terraform, and is used by the PostgreSQL provider. If the password is changed outside Terraform, it will revoke Terraform's ability to refresh the state. 

This can be fixed by first deleting the admin password from the Terraform state, forcing it to be regenerated. Once it has been deleted, apply the new password on the server resource to regenerate and set a new password, using the [-target flag](https://www.terraform.io/docs/cli/commands/plan.html#resource-targeting).

**Use with caution**.

#### Example
`terraform state rm module.postgresql.random_password.admin`

`terraform apply -target=module.postgresql.azurerm_postgresql_server.main`

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 2.57 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | >= 2.0.3 |
| <a name="requirement_postgresql"></a> [postgresql](#requirement\_postgresql) | 1.12.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 2.57 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | >= 2.0.3 |
| <a name="provider_postgresql"></a> [postgresql](#provider\_postgresql) | 1.12.0 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_postgresql_flexible_server.main](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server) | resource |
| [azurerm_postgresql_flexible_server_configuration.configs](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_configuration) | resource |
| [azurerm_postgresql_flexible_server_database.databases](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/postgresql_flexible_server_database) | resource |
| [kubernetes_secret.db_credentials](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/secret) | resource |
| [postgresql_grant.roles](https://registry.terraform.io/providers/cyrilgdn/postgresql/1.12.0/docs/resources/grant) | resource |
| [postgresql_role.roles](https://registry.terraform.io/providers/cyrilgdn/postgresql/1.12.0/docs/resources/role) | resource |
| [postgresql_schema.schemas](https://registry.terraform.io/providers/cyrilgdn/postgresql/1.12.0/docs/resources/schema) | resource |
| [random_password.admin](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [random_password.roles](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/password) | resource |
| [azurerm_private_dns_zone.dns_zone](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/private_dns_zone) | data source |
| [azurerm_subnet.psqlflex](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_administrator_login"></a> [administrator\_login](#input\_administrator\_login) | The administrator login for the PostgreSQL Server. | `string` | `"pgsqladminlocal"` | no |
| <a name="input_app_name"></a> [app\_name](#input\_app\_name) | The name of the associated application | `string` | n/a | yes |
| <a name="input_backup_retention_days"></a> [backup\_retention\_days](#input\_backup\_retention\_days) | Backup retention days for the server, supported values are between 7 and 35 days. | `number` | `14` | no |
| <a name="input_database_roles"></a> [database\_roles](#input\_database\_roles) | Map of database roles and grants. | `map(any)` | <pre>{<br>  "application": {<br>    "grants": [<br>      {<br>        "database": "application",<br>        "object_type": "database",<br>        "privileges": [<br>          "CONNECT",<br>          "TEMPORARY"<br>        ],<br>        "schema": "public"<br>      }<br>    ],<br>    "name": "appuser",<br>    "password_override": null,<br>    "replication": false,<br>    "roles": []<br>  }<br>}</pre> | no |
| <a name="input_databases"></a> [databases](#input\_databases) | The list of names of the PostgreSQL Database, which needs to be a valid PostgreSQL identifier. Changing this forces a new resource to be created. | `list(string)` | <pre>[<br>  "application"<br>]</pre> | no |
| <a name="input_db_charset"></a> [db\_charset](#input\_db\_charset) | Specifies the Charset for the PostgreSQL Database, which needs to be a valid PostgreSQL Charset. Changing this forces a new resource to be created. | `string` | `"UTF8"` | no |
| <a name="input_db_collation"></a> [db\_collation](#input\_db\_collation) | Specifies the Collation for the PostgreSQL Database, which needs to be a valid PostgreSQL Collation. Note that Microsoft uses different notation - en-US instead of en\_US. Changing this forces a new resource to be created. | `string` | `"nb_NO.utf8"` | no |
| <a name="input_drop_cascade"></a> [drop\_cascade](#input\_drop\_cascade) | Whether to drop all the objects that are contained in a schema on deletion. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment name, e.g. 'dev' | `string` | n/a | yes |
| <a name="input_kubernetes_create_secret"></a> [kubernetes\_create\_secret](#input\_kubernetes\_create\_secret) | Whether to create a Kubernetes secret | `bool` | `true` | no |
| <a name="input_kubernetes_namespaces"></a> [kubernetes\_namespaces](#input\_kubernetes\_namespaces) | The namespaces where a Kubernetes secret should be created | `list(string)` | `[]` | no |
| <a name="input_kubernetes_secret_name"></a> [kubernetes\_secret\_name](#input\_kubernetes\_secret\_name) | The name of the Kubernetes secret to create | `string` | `null` | no |
| <a name="input_landing_zone"></a> [landing\_zone](#input\_landing\_zone) | The landing zone name, e.g. 'dev-001' | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Default Azure resource location | `string` | `"Norway East"` | no |
| <a name="input_network_resource_group_prefix"></a> [network\_resource\_group\_prefix](#input\_network\_resource\_group\_prefix) | Name prefix of the network resource group | `string` | `"rg-networks"` | no |
| <a name="input_postgresql_server_name"></a> [postgresql\_server\_name](#input\_postgresql\_server\_name) | Specifies the name of the PostgreSQL Server. Changing this forces a new resource to be created. | `string` | `null` | no |
| <a name="input_psql_connections_subnet_name_prefix"></a> [psql\_connections\_subnet\_name\_prefix](#input\_psql\_connections\_subnet\_name\_prefix) | Subnet name prefix of subnets where Azure private endpoint connections will be created | `string` | `"snet-psqlflex-workloads"` | no |
| <a name="input_public_network_access_enabled"></a> [public\_network\_access\_enabled](#input\_public\_network\_access\_enabled) | Whether or not public network access is allowed for this server. This should always be set to 'false'. | `bool` | `false` | no |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group in which the PostgreSQL Server will be created. | `string` | n/a | yes |
| <a name="input_server_configurations"></a> [server\_configurations](#input\_server\_configurations) | A map of PostgreSQL configurations to enable. | `map(string)` | `{}` | no |
| <a name="input_server_version"></a> [server\_version](#input\_server\_version) | Specifies the version of PostgreSQL to use. Valid values are 9.5, 9.6, and 10.0. Changing this forces a new resource to be created. | `string` | n/a | yes |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | Specifies the SKU Name for this PostgreSQL Server. The name of the SKU, follows the tier + family + cores pattern (e.g. GP\_Gen5\_8) - note: Basic tier (B) VMs are not supported. | `string` | n/a | yes |
| <a name="input_storage_mb"></a> [storage\_mb](#input\_storage\_mb) | Max storage allowed for a server. Possible values are between 5120 MB(5GB) and 1048576 MB(1TB) for the Basic SKU and between 5120 MB(5GB) and 4194304 MB(4TB) for General Purpose/Memory Optimized SKUs. | `number` | `32768` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to attach to resources | `map(any)` | n/a | yes |
| <a name="input_vnet_name_prefix"></a> [vnet\_name\_prefix](#input\_vnet\_name\_prefix) | Vnet name prefix where the nodes and pods will be deployed | `string` | `"vnet"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_administrator_login"></a> [administrator\_login](#output\_administrator\_login) | n/a |
| <a name="output_administrator_password"></a> [administrator\_password](#output\_administrator\_password) | n/a |
| <a name="output_application_login"></a> [application\_login](#output\_application\_login) | n/a |
| <a name="output_application_login_password"></a> [application\_login\_password](#output\_application\_login\_password) | n/a |
| <a name="output_custom_dns_configs"></a> [custom\_dns\_configs](#output\_custom\_dns\_configs) | n/a |
| <a name="output_roles"></a> [roles](#output\_roles) | n/a |
| <a name="output_server_fqdn"></a> [server\_fqdn](#output\_server\_fqdn) | n/a |
| <a name="output_server_id"></a> [server\_id](#output\_server\_id) | n/a |
| <a name="output_server_name"></a> [server\_name](#output\_server\_name) | n/a |
<!-- END_TF_DOCS -->