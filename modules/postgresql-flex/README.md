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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| administrator_login | The administrator login for the PostgreSQL server | string | pgsqladminlocal | no |
| app_name | The name of the associated application | string | N/A | yes |
| resource_group_name | The name of the resource group in which the PostgreSQL Server will be created.| string |-| yes|
| backup_retention_days | Backup retention days for the server | number | 14 | no |
| databases | List of databases to create | list(string) | N/A | yes |
| database_roles | Map of database roles and grants to create | map | N/A | yes |
| db_charset | Specifies the charset for databases | string | UTF8 | no |
| db_collation | Specifies the collation for databases | string | nb-NO | no |
| drop_cascade | Whether to drop all the objects that are contained in a schema on deletion | bool | false | no |
| environment | The environment name, e.g. 'dev' | string | N/A | yes |
| kubernetes_create_secret | Whether to create Kubernetes secret(s) | bool | true | no |
| kubernetes_namespaces | The namespace(s) where Kubernetes secret(s) should be created | list(string) | [] | no |
| kubernetes_secret_name | The name of the Kubernetes secret(s) to create | string | Generated | no |
| landing_zone | The landing zone name, e.g. 'dev-001' | string | N/A | yes |
| location | Azure region where the cluster should be deployed | string | Norway East | no |
| postgresql_server_name | Specifies the name of the PostgreSQL Server | string | Generated | no |
| public_network_access_enabled | Whether to enable public network access | bool | false | no |
| server_configurations | PostgreSQL configuration parameters | map(string) | N/A | no |
| server_version | Specifies the version of PostgreSQL to use (e.g. "11")| string | N/A | yes |
| sku_name | Specifies the SKU name for this PostgreSQL server ([more info](#database-instance-sizing)) | string | N/A | yes |
| storage_mb | Max storage allowed for a server in megabytes (e.g. 5120) | number | N/A | yes |
| tags | Tags to apply to created resources | map | N/A | yes |

## Outputs

| Name | Description |
|------|-------------|
| administrator_login | The server administrator login |
| administrator_login_password | The server administrator password |
| application_login | The application role login |
| application_login_password | The application role password |
| custom_dns_configs | Custom DNS configurations as exported by the private endpoint resource |
| roles | All PostgreSQL roles provisioned by this module |
| server_name | The server instance name |
| server_id   | The server instance ID
| server_fqdn | The server instance host |

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
