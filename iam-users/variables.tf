variable "iam_account_alias" {
  type        = string
  description = "A globally unique identifier, human-readable for your AWS account"
}

variable "set_iam_account_alias" {
  type        = bool
  description = "Whether or not to set the account alias (useful to set to false when iam-users and iam-resources module are being deployed into the same account)"
  default     = true
}

variable "multi_factor_auth_age" {
  type        = string
  description = "The amount of time (in seconds) for a user session to be valid"
  default     = "14400"
}

variable "password_policy" {
  type        = map(string)
  description = "A map of password policy parameters you want to set differently from the defaults"
  default     = {}
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
  description = "Administrator group name"
  default     = "admins"
}

variable "user_group_name" {
  type        = string
  description = "User group name"
  default     = "users"
}

data "aws_caller_identity" "current" {}

locals {
  resources_account_id = length(var.resources_account_id) > 0 ? var.resources_account_id : data.aws_caller_identity.current.account_id
  password_policy = merge({
    require_uppercase_characters   = "true"
    require_lowercase_characters   = "true"
    require_symbols                = "true"
    require_numbers                = "true"
    minimum_password_length        = "32"
    password_reuse_prevention      = "5"
    max_password_age               = "90"
    allow_users_to_change_password = "true"
  }, var.password_policy)
}

provider "aws" {
  version = "~> 2.19.0"
}
