data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Policy to allow for the Config service to assume a role this is assigned to
data "aws_iam_policy_document" "config_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

# Policy for accessing the S3 bucket where Config artifacts are stored in
data "aws_iam_policy_document" "allow_s3_access_for_aws_config_policy_document" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetBucketAcl"]
    resources = [local.aws_config_s3_bucket_arn]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }
  }

  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${local.aws_config_s3_bucket_arn}/${var.bucket_key_prefix}/AWSLogs/${local.bucket_account_id}/Config/*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["true"]
    }

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }
}
