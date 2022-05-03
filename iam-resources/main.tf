locals {
  administrator_access_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  iam_read_only_access_policy_arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
  power_user_access_policy_arn    = "arn:aws:iam::aws:policy/PowerUserAccess"
  users_account_id                = length(var.users_account_id) > 0 ? var.users_account_id : data.aws_caller_identity.current.account_id
}

resource "aws_iam_account_alias" "iam_account_alias" {
  count         = var.set_iam_account_alias ? 1 : 0
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

resource "aws_iam_policy" "user_no_vpc_access_policy" {
  name        = "user_no_vpc_access_policy"
  description = "deny user access to VPC related commands"

  policy = data.aws_iam_policy_document.no_vpc_access_policy_document.json
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

resource "aws_iam_policy_attachment" "user_access_no_vpc_access_policy_attachment" {
  name       = "user_access_no_vpc_access_policy_attachment"
  roles      = [aws_iam_role.user_access_role.name]
  policy_arn = aws_iam_policy.user_no_vpc_access_policy.arn
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
