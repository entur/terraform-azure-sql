variable "app_name" {
  type    = string
  default = "tfmodules"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "landing_zone" {
  type    = string
  default = "dev-001"
}

variable "location" {
  type    = string
  default = "Norway East"
}
variable "resource_group_name" {
  type    = string
  default = "rg-app-tfmodules-dev"
}
variable "tags" {
  type    = map(any)
  default = {}
}

variable "databases" {
  type    = list(string)
  default = ["database-1", "database-2"]
}

variable "database_roles" {
  type = map(any)
  default = {
    application = {
      name              = "tfmodules"
      password_override = null
      replication       = false
      roles             = []
      grants = [
        {
          database    = "database-1"
          schema      = "user1"
          object_type = "database"
          privileges  = ["CONNECT"]
        },
        {
          database    = "database-2"
          schema      = "user2"
          object_type = "database"
          privileges  = ["CONNECT"]
        }
      ]
    }
  }
}

variable "maintenance_window" {
  description = "Configure maintenance window day, start hour and start minute, default is Sunday= '0', hour= '0', minute= '0' "
  type        = map(string)
  default = {
    day_of_week  = 5
    start_hour   = 22
    start_minute = 0
  }
}
