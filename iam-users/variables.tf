variable "iam_account_alias" {
  type        = string
  description = "A globally unique, human-readable identifier for your AWS account"
  default     = null
}

variable "admin_multi_factor_auth_age" {
  type        = number
  description = "The amount of time (in minutes) for a admin session to be valid"
  default     = 60 # 1 hour
}

variable "user_multi_factor_auth_age" {
  type        = number
  description = "The amount of time (in minutes) for a user session to be valid"
  default     = 240 # 4 hours
}

variable "password_policy" {
  type        = map(string)
  description = "A map of password policy parameters you want to set differently from the defaults"
  default = {
    require_uppercase_chars   = "true"
    require_lowercase_chars   = "true"
    require_symbols           = "true"
    require_numbers           = "true"
    minimum_password_length   = "32"
    password_reuse_prevention = "5"
    max_password_age          = "90"
  }
}

variable "resources_account_id" {
  type        = string
  description = "The account ID of the AWS account you want to start resources in"
  default     = ""
}

variable "resource_admin_role_name" {
  type        = string
  description = "The name of the administrator role one is supposed to assume in the resource account"
  default     = "resource-admin"
}

variable "resource_user_role_name" {
  type        = string
  description = "The name of the user role one is supposed to assume in the resource account"
  default     = "resource-user"
}

variable "admin_group_name" {
  type        = string
  description = "The name of the initial group created for administrators"
  default     = "admins"
}

variable "user_group_name" {
  type        = string
  description = "The name of the initial group created for users"
  default     = "users"
}

variable "additional_admin_groups" {
  type        = list(string)
  description = "A list of additional groups to create associated with administrative privileges"
  default     = []
}

variable "additional_user_groups" {
  type        = list(string)
  description = "A list of additional groups to create associated with regular users"
  default     = []
}

variable "iam_users" {
  type        = map(map(list(string)))
  description = "A list of maps of users and their groups. Default is to create no users."
  default     = {}
}
