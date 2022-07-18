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
          database    = "cats"
          schema      = "cats"
          object_type = "schema"
          privileges  = ["USAGE", "CREATE"]
        },
        {
          database    = "dogs"
          schema      = "dogs"
          object_type = "database"
          privileges  = ["CONNECT"]
        },
        {
          database    = "dogs"
          schema      = "dogs"
          object_type = "schema"
          privileges  = ["USAGE", "CREATE"]
        }
      ]
    }
    additional_role = {
      name              = "gorilla"
      password_override = null
      replication       = false
      grants = [
        {
          database    = "bananas"
          schema      = "bananas"
          object_type = "database"
          privileges  = ["CONNECT"]
        },
        {
          database    = "bananas"
          schema      = "bananas"
          object_type = "schema"
          privileges  = ["USAGE", "CREATE"]
        }
      ]
    }
  }
}
