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
      grants = [
        {
          database    = "cats"
          schema      = "public"
          object_type = "database"
          privileges  = ["CONNECT"]
        },
        {
          database    = "cats"
          schema      = "public"
          object_type = "schema"
          privileges  = ["USAGE", "CREATE"]
        },
        {
          database    = "dogs"
          schema      = "public"
          object_type = "database"
          privileges  = ["CONNECT"]
        },
        {
          database    = "dogs"
          schema      = "public"
          object_type = "schema"
          privileges  = ["USAGE", "CREATE"]
        }
      ]
    }
  }
}
