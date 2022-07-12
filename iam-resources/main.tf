/**
*
* ## iam-resources
*
* A module to configure the "resources" account modelled after the common security principle of separating users from resource accounts through a MFA-enabled role-assumption bridge.
* Please see the [iam-users](https://github.com/moritzheiber/terraform-aws-core-modules/tree/main/iam-users) module for further explanation. It is generally assumed that this module isn't deployed on its own.
* 
* ### Usage example
* ```hcl
* module "iam_resources" {
*   source            = "git::https://github.com/moritzheiber/terraform-aws-core-modules.git//iam-resources"

    # Optional parameter for specifying a different AWS account, the default is to use the same account
*   users_account_id = "id-of-the-users-account"
* }
* 
* ``` 
*/

locals {
  administrator_access_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  iam_read_only_access_policy_arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
  power_user_access_policy_arn    = "arn:aws:iam::aws:policy/PowerUserAccess"
  users_account_id                = var.users_account_id == null ? data.aws_caller_identity.current.account_id : var.users_account_id
  admin_multi_factor_auth_age     = var.admin_multi_factor_auth_age * 60
  user_multi_factor_auth_age      = var.user_multi_factor_auth_age * 60
}

resource "aws_iam_account_alias" "iam_account_alias" {
  count         = var.iam_account_alias == null ? 0 : 1
  account_alias = var.iam_account_alias
}

# Roles
resource "aws_iam_role" "admin_access_role" {
  name = var.admin_access_role_name

  assume_role_policy = data.aws_iam_policy_document.admin_access_role_policy.json
}

resource "aws_iam_role" "user_access_role" {
  name = var.user_access_role_name

  assume_role_policy = data.aws_iam_policy_document.user_access_role_policy.json
}

resource "aws_iam_policy" "user_access_policy" {
  name        = "user_access_policy"
  description = "User access for roles"

  policy = data.aws_iam_policy_document.user_access_policy_document.json
}

# Policy attachments for roles
resource "aws_iam_policy_attachment" "admin_access_policy_attachment" {
  name       = "admin_access_policy_attachment"
  roles      = [aws_iam_role.admin_access_role.name]
  policy_arn = local.administrator_access_policy_arn
}

resource "aws_iam_policy_attachment" "user_access_policy_attachment" {
  name       = "user_access_policy_attachment"
  roles      = [aws_iam_role.user_access_role.name]
  policy_arn = aws_iam_policy.user_access_policy.arn
}

resource "aws_iam_policy_attachment" "user_access_iam_read_only_policy_attachment" {
  name       = "user_access_iam_read_only_policy_attachment"
  roles      = [aws_iam_role.user_access_role.name]
  policy_arn = local.iam_read_only_access_policy_arn
}

resource "aws_iam_policy_attachment" "user_access_power_user_policy_attachment" {
  name       = "user_access_power_user_policy_attachment"
  roles      = [aws_iam_role.user_access_role.name]
  policy_arn = local.power_user_access_policy_arn
}
