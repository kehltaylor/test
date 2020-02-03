
#
# TERRAFORM AUTHENTICATION
#
variable "tenant_id" {
  type = string
}
variable "subscription_id" {
  type = string
}
variable "client_id" {
  type = string
}
variable "client_secret" {
  type = string
}

#
# AZURE VARIABLES
#

variable "location" { # Resources location
  type = string
  default = "West Europe"
}

variable "environment" { # Deployement environment
  type = string
  default = "staging"
}

variable "application" { # Unique name of the all project
  type = string
  default = "esgiapp"
}

#
# SERVERLESS VARIABLES
#

variable "function_username" { # Username of basic auth
  type = string
  default = "root"
}

variable "function_password" { # Password of basic auth
  type = string
  default = "root"
}

variable "github_address_fonction_app" {
  type = string
  default = ""
}

#
# MYSQL VARIABLES
#

variable "mysql_server_login" { # User of the mysql server
  type = string
  default = "adm_usr"
}

variable "mysql_server_password" { # Password of the mysql server
  type = string
  default = "p@ssw0rd"
}

variable "mysql_server_version" { # Version of the mysql server
  type = string
  default = "5.7"
}

variable "mysql_database_name" { # Name of the database
  type = string
  default = "db"
}
