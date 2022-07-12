data "aws_caller_identity" "current" {}

# AssumeRole policies to enforce MFA when assuming these from either the same or a different account
data "aws_iam_policy_document" "admin_access_role_policy" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }

    condition {
      test     = "NumericLessThan"
      variable = "aws:MultiFactorAuthAge"
      values   = [local.admin_multi_factor_auth_age]
    }

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${local.users_account_id}:root",
      ]
    }
  }
}

data "aws_iam_policy_document" "user_access_role_policy" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    condition {
      test     = "Bool"
      variable = "aws:MultiFactorAuthPresent"
      values   = ["true"]
    }

    condition {
      test     = "NumericLessThan"
      variable = "aws:MultiFactorAuthAge"
      values   = [local.user_multi_factor_auth_age]
    }

    principals {
      type = "AWS"

      identifiers = [
        "arn:aws:iam::${local.users_account_id}:root",
      ]
    }
  }
}

# This denies the passing of the admin or user 
data "aws_iam_policy_document" "user_access_policy_document" {
  statement {
    effect = "Allow"

    actions = [
      "iam:PassRole",
    ]

    not_resources = [
      aws_iam_role.user_access_role.arn,
      aws_iam_role.admin_access_role.arn
    ]
  }
}
