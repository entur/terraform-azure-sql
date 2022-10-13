variable "app_name" {
  type    = string
  default = "validate"
}

variable "environment" {
  type    = string
  default = "sandbox"
}

variable "landing_zone" {
  type    = string
  default = "sandbox-001"
}

variable "location" {
  type    = string
  default = "Norway East"
}

variable "resource_group_name" {
  type    = string
  default = "validate"
}

variable "tags" {
  type    = map(any)
  default = {}
}

variable "databases" {
  type    = list(string)
  default = ["cats", "dogs"]
}

variable "database_roles" {
  type = map(any)
  default = {
    application = {
      name              = "appuser"
      password_override = null
      replication       = false
      roles             = []
      grants = [
        {
          database    = "cats"
          schema      = "cats"
          object_type = "database"
          privileges  = ["CONNECT"]
        },
        {
          database    = "dogs"
          schema      = "dogs"
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
