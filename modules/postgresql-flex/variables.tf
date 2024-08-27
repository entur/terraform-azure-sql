variable "location" {
  description = "Default Azure resource location"
  type        = string
  default     = "Norway East"
}

variable "resource_group_name" {
  description = "The name of the resource group in which the PostgreSQL Server will be created."
  type        = string
}

variable "app_name" {
  description = "The name of the associated application"
  type        = string
}

variable "environment" {
  description = "The environment name, e.g. 'dev'"
  type        = string
}

variable "landing_zone" {
  description = "The landing zone name, e.g. 'dev-001'"
  type        = string
}

variable "tags" {
  description = "Tags to attach to resources"
  type        = map(any)
}

# Kubernetes variables
variable "kubernetes_create_secret" {
  description = "Whether to create a Kubernetes secret"
  type        = bool
  default     = true
}

variable "kubernetes_namespaces" {
  description = "The namespaces where a Kubernetes secret should be created"
  type        = list(string)
  default     = []
}

variable "kubernetes_secret_name" {
  description = "The name of the Kubernetes secret to create"
  type        = string
  default     = null
}

# Network variables
variable "vnet_name_prefix" {
  description = "Vnet name prefix where the nodes and pods will be deployed"
  type        = string
  default     = "vnet"
}

variable "aks_connections_subnet_name_prefix" {
  description = "Subnet name prefix of subnets where Azure private endpoint connections will be created"
  type        = string
  default     = "snet-aks-connections"
}

variable "network_resource_group_prefix" {
  description = "Name prefix of the network resource group"
  type        = string
  default     = "rg-networks"
}

# PostgreSQL variables
variable "postgresql_server_name" {
  description = "Specifies the name of the PostgreSQL Server. Changing this forces a new resource to be created."
  type        = string
  default     = null # Generated if empty
}

variable "sku_name" {
  description = "Specifies the SKU Name for this PostgreSQL Server. The name of the SKU, follows the tier + family + cores pattern (e.g. GP_Gen5_8) - note: Basic tier (B) VMs are not supported. Refer to https://learn.microsoft.com/en-us/azure/postgresql/flexible-server/concepts-compute#compute-tiers-vcores-and-server-types"
  type        = string
}

variable "storage_mb" {
  description = "Max storage allowed for a server. Possible values are between 5120 MB(5GB) and 1048576 MB(1TB) for the Basic SKU and between 5120 MB(5GB) and 4194304 MB(4TB) for General Purpose/Memory Optimized SKUs."
  type        = number
  default     = 32768
}

variable "backup_retention_days" {
  description = "Backup retention days for the server, supported values are between 7 and 35 days."
  type        = number
  default     = 14
}

variable "server_version" {
  description = "Specifies the version of PostgreSQL to use. Changing this forces a new resource to be created."
  type        = string
}

variable "db_charset" {
  description = "Specifies the Charset for the PostgreSQL Database, which needs to be a valid PostgreSQL Charset. Changing this forces a new resource to be created."
  type        = string
  default     = "UTF8"
}

variable "db_collation" {
  description = "Specifies the Collation for the PostgreSQL Database, which needs to be a valid PostgreSQL Collation. Note that Microsoft uses different notation - en-US instead of en_US. Changing this forces a new resource to be created."
  type        = string
  default     = "nb_NO.utf8"
}

variable "drop_cascade" {
  description = "Whether to drop all the objects that are contained in a schema on deletion."
  type        = bool
  default     = false
}

variable "server_configurations" {
  description = "A map of PostgreSQL configurations to enable."
  type        = map(string)
  default     = {}
}

variable "administrator_login" {
  description = "The administrator login for the PostgreSQL Server."
  type        = string
  default     = "pgsqladminlocal"
}

variable "databases" {
  description = "The list of names of the PostgreSQL Database, which needs to be a valid PostgreSQL identifier. Changing this forces a new resource to be created."
  type        = list(string)
  default     = ["application"]
}

# Note: This map requires an entry with the 'application' key: it is used for provisioning k8s credentials etc.
variable "database_roles" {
  description = "Map of database roles and grants."
  type        = map(any)
  default = {
    application = {
      name              = "appuser"
      password_override = null # Password will be generated if left empty
      replication       = false
      roles             = [] # Defines list of roles which will be granted to this new role.
      grants = [
        {
          database    = "application"
          schema      = "public"
          object_type = "database"
          privileges  = ["CONNECT", "TEMPORARY"]
        }
      ]
    }
  }
}

variable "maintenance_window" {
  description = "Configure maintenance window day, start hour and start minute"
  type        = map(string)
  default     = null
}
