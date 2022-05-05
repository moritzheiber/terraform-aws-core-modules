locals {
  config_policy_arn         = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
  bucket_account_id         = length(var.bucket_account_id) > 0 ? var.bucket_account_id : data.aws_caller_identity.current.account_id
  aws_config_s3_bucket_arn  = var.enable_lifecycle_management_for_s3 ? aws_s3_bucket.config_with_lifecycle[0].arn : aws_s3_bucket.config_without_lifecycle[0].arn
  aws_config_s3_bucket_name = var.enable_lifecycle_management_for_s3 ? aws_s3_bucket.config_with_lifecycle[0].bucket : aws_s3_bucket.config_without_lifecycle[0].bucket

  complex_rules_password_policy = {
    IAM_PASSWORD_POLICY = {
      owner = "AWS"
      input_parameters = {
        RequireUppercaseCharacters = var.password_policy["require_uppercase_chars"]
        RequireLowercaseCharacters = var.password_policy["require_lowercase_chars"]
        RequireSymbols             = var.password_policy["require_symbols"]
        RequireNumbers             = var.password_policy["require_numbers"]
        MinimumPasswordLength      = var.password_policy["minimum_password_length"]
        PasswordReusePrevention    = var.password_policy["password_reuse_prevention"]
        MaxPasswordAge             = var.password_policy["max_password_age"]
      }
    }
  }

  complex_rules_group_membership = length(var.iam_user_groups) > 0 ? {
    IAM_USER_GROUP_MEMBERSHIP_CHECK = {
      owner            = "AWS"
      input_parameters = var.iam_user_groups
    }
  } : {}

  complex_rules_approved_ami_tags = length(var.amis_by_tag_key_and_value_list) > 0 ? {
    APPROVED_AMIS_BY_TAG = {
      owner = "AWS"
      input_parameters = {
        amisByTagKeyAndValue = var.amis_by_tag_key_and_value_list
      }
    }
  } : {}

  complex_rules_access_key_rotation = length(var.max_access_key_age) > 0 ? {
    ACCESS_KEYS_ROTATED = {
      owner = "AWS"
      input_parameters = {
        maxAccessKeyAge = var.max_access_key_age
      }
    }
  } : {}

  complex_rules_desired_instance_type = length(var.desired_instance_types) > 0 ? {
    DESIRED_INSTANCE_TYPE = {
      owner = "AWS"
      input_parameters = {
        maxAccessKeyAge = var.desired_instance_types
      }
    }
  } : {}

  complex_rules = merge(
    local.complex_rules_password_policy,
    local.complex_rules_group_membership,
    local.complex_rules_approved_ami_tags,
    local.complex_rules_access_key_rotation,
    local.complex_rules_desired_instance_type,
    var.complex_config_rules,
  )
}

resource "aws_iam_role" "config" {
  name               = var.iam_role_name
  assume_role_policy = data.aws_iam_policy_document.config_assume_role_policy.json
}

resource "aws_iam_policy" "allow_s3_access_for_aws_config_policy" {
  name   = "allow_s3_access_for_aws_config_policy"
  policy = data.aws_iam_policy_document.allow_s3_access_for_aws_config_policy_document.json
}

resource "aws_iam_role_policy_attachment" "config" {
  role       = aws_iam_role.config.name
  policy_arn = local.config_policy_arn
}

resource "aws_iam_role_policy_attachment" "allow_s3_access_for_aws_config_attachment" {
  role       = aws_iam_role.config.name
  policy_arn = aws_iam_policy.allow_s3_access_for_aws_config_policy.arn
}

# S3 buckets
resource "aws_s3_bucket" "config_with_lifecycle" {
  count         = var.enable_lifecycle_management_for_s3 ? 1 : 0
  bucket_prefix = var.bucket_prefix
}

resource "aws_s3_bucket" "config_without_lifecycle" {
  count         = var.enable_lifecycle_management_for_s3 ? 0 : 1
  bucket_prefix = var.bucket_prefix

  force_destroy = true
}

resource "aws_s3_bucket_acl" "acl" {
  bucket = local.aws_config_s3_bucket_name
  acl    = "private"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "enforce_encryption" {
  bucket = local.aws_config_s3_bucket_name

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.s3_kms_sse_encryption_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = local.aws_config_s3_bucket_name
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "config" {
  count  = var.enable_lifecycle_management_for_s3 ? 1 : 0
  bucket = aws_s3_bucket.config_with_lifecycle[0].id

  rule {
    id = "prefix_matching"
    filter {
      prefix = "${var.bucket_key_prefix}/"
    }

    noncurrent_version_expiration {
      noncurrent_days = var.lifecycle_bucket_expiration
    }

    expiration {
      days = var.lifecycle_bucket_expiration
    }

    status = "Enabled"
  }
}

# AWS Config resources and rules
resource "aws_config_configuration_recorder" "config" {
  name     = var.config_recorder_name
  role_arn = aws_iam_role.config.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "config" {
  name           = var.config_delivery_channel_name
  s3_bucket_name = local.aws_config_s3_bucket_name
  s3_key_prefix  = var.bucket_key_prefix

  snapshot_delivery_properties {
    delivery_frequency = var.delivery_frequency
  }

  depends_on = [aws_config_configuration_recorder.config]
}

resource "aws_config_configuration_recorder_status" "config" {
  name       = aws_config_configuration_recorder.config.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.config]
}

# Simple Config rules which just require the identifier and the owner
resource "aws_config_config_rule" "rule_simple" {
  for_each = var.simple_config_rules
  name     = lower(each.key)

  source {
    owner             = each.value
    source_identifier = each.key
  }

  depends_on = [aws_config_configuration_recorder.config]
}

# These are more complicated because they require more input
resource "aws_config_config_rule" "rule_complex" {
  for_each = local.complex_rules
  name     = lower(each.key)

  source {
    owner             = each.value.owner
    source_identifier = each.key
  }

  input_parameters = jsonencode(each.value.input_parameters)

  depends_on = [aws_config_configuration_recorder.config]
}
