/**
*
* ## iam-users
*
* A module to configure the "users" account modeled after a common security principle of separating users from resource accounts through a MFA-enabled role-assumption bridge:
* 
* ![AWS IAM setup illustration](https://raw.githubusercontent.com/moritzheiber/terraform-aws-core-modules/main/files/aws_iam_setup.png)
* 
* These strict separation of privileges follow [an article I wrote a while ago](https://www.thoughtworks.com/insights/blog/using-aws-security-first-class-citizen).
* You can also create IAM users and IAM groups with this module and assign the users to specific groups. The module will create two default groups, one for admins and users, which you can disable by setting the `admin_group_name` and `user_group_name` to an empty string.
* 
* Creating additional users is done by passing a map called `users` to the module, with a group mapping attached to them (the best practice is to never have users live "outside" of groups).
*
* ```hcl
* variable "iam_users" {
*   type = map(map(set(string)))
*   default = {
*     my_user = {
*       groups = ["admins"]
*     }
*   }
* }
* 
* module "iam_users" {
*   source            = "git::https://github.com/moritzheiber/terraform-aws-core-modules.git//iam-users"
*
*   iam_account_alias = "my_unique_alias"
*   iam_users = var.iam_users
* }
* ```
* 
* This will run the module and create all the necessary permissions along with a user belonging to the `admins` groups.
*
*/

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
  admin_groups = compact(concat([var.admin_group_name], var.additional_admin_groups))
  user_groups  = compact(concat([var.user_group_name], var.additional_user_groups))
}

resource "aws_iam_policy" "aws_access_key_self_service" {
  name        = "aws_access_key_self_service"
  description = "Policy for access key self service"

  policy = data.aws_iam_policy_document.aws_access_key_self_service_policy.json
}

#tfsec:ignore:general-secrets-sensitive-in-attribute
resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = local.password_policy["minimum_password_length"]
  max_password_age               = local.password_policy["max_password_age"]
  password_reuse_prevention      = local.password_policy["password_reuse_prevention"]
  require_lowercase_characters   = local.password_policy["require_lowercase_characters"]
  require_numbers                = local.password_policy["require_numbers"]
  require_uppercase_characters   = local.password_policy["require_uppercase_characters"]
  require_symbols                = local.password_policy["require_symbols"]
  allow_users_to_change_password = local.password_policy["allow_users_to_change_password"]
}

resource "aws_iam_policy" "aws_list_iam_users" {
  name        = "aws_list_iam_users"
  description = "Let users see the list of users"

  policy = data.aws_iam_policy_document.aws_list_iam_users_policy.json
}

resource "aws_iam_policy" "aws_mfa_self_service" {
  name        = "aws_mfa_self_service"
  description = "Policy for MFA self service"

  policy = data.aws_iam_policy_document.aws_mfa_self_service_policy.json
}

resource "aws_iam_account_alias" "iam_account_alias" {
  count         = var.set_iam_account_alias ? 1 : 0
  account_alias = var.iam_account_alias
}

# Users
resource "aws_iam_user" "users" {
  for_each = var.iam_users
  name     = each.key
}

resource "aws_iam_user_group_membership" "users_group_memberships" {
  depends_on = [
    aws_iam_user.users,
    aws_iam_group.groups
  ]
  for_each = var.iam_users
  user     = each.key

  groups = each.value["groups"]
}

# Groups
resource "aws_iam_group" "groups" {
  for_each = toset(concat(
    local.admin_groups,
    local.user_groups
  ))
  name = each.key
}

# Group policy assignments
resource "aws_iam_policy_attachment" "users_mfa_self_service" {
  name       = "users_mfa_self_service"
  groups     = values(aws_iam_group.groups)[*].name
  policy_arn = aws_iam_policy.aws_mfa_self_service.arn
}

resource "aws_iam_policy_attachment" "users_access_key_self_service" {
  name       = "users_access_key_self_service"
  groups     = values(aws_iam_group.groups)[*].name
  policy_arn = aws_iam_policy.aws_access_key_self_service.arn
}

resource "aws_iam_policy_attachment" "users_list_iam_users" {
  name       = "users_list_iam_users"
  groups     = values(aws_iam_group.groups)[*].name
  policy_arn = aws_iam_policy.aws_list_iam_users.arn
}

resource "aws_iam_group_policy" "assume_role_admin_access_group_policy" {
  for_each = toset(local.admin_groups)
  name     = "admin_access_group_policy"
  group    = aws_iam_group.groups[each.key].id

  policy = data.aws_iam_policy_document.assume_role_admin_access_group_policy_document.json
}

resource "aws_iam_group_policy" "assume_role_users_access_group_policy" {
  for_each = toset(local.user_groups)
  name     = "users_access_group_policy"
  group    = aws_iam_group.groups[each.key].id

  policy = data.aws_iam_policy_document.assume_role_users_access_group_policy_document.json
}
