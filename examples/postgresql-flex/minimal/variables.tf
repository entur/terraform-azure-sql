variable "app_name" {
  type    = string
  default = "myapp"
}

variable "environment" {
  type    = string
  default = "myenv"
}

variable "landing_zone" {
  type    = string
  default = "mylandingzone"
}

variable "location" {
  type    = string
  default = "Norway East"
}
variable "resource_group_name" {
  type    = string
  default = "myapprg"
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

variable "maintenance_win_day_of_week" {
  description = "The day of week for maintenance window, where the week starts on a Sunday, i.e. Sunday = 0, Monday = 1. Defaults to 0."
  type        = string
  default     = "1"
}

variable "maintenance_win_start_hour" {
  description = "The start hour for maintenance window. Defaults to 0."
  type        = string
  default     = "0"
}

variable "maintenance_win_start_minute" {
  description = "The start minute for maintenance window. Defaults to 0."
  type        = string
  default     = "0"
}