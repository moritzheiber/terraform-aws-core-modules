/**
* ## Config
* 
* The module configures AWS Config to monitor your account for non-compliant resources.
* You can freely choose which checks to use or discard by modifying the `enable_config_rules`, `disable_config_rules` and `complex_config_rules` variables.
*
* As an example, if you'd wish to enable `AUTOSCALING_CAPACITY_REBALANCING` and disable the `INSTANCES_IN_VPC` check, which is enabled by default, you could use the following code:
*
* ```hcl
* module "aws_config" {
*     source = "git::https://github.com/moritzheiber/terraform-aws-core-modules//config"
*     
*     enable_simple_rules = ["AUTOSCALING_CAPACITY_REBALANCING"]
*     disable_simple_rules = ["INSTANCE_IN_VPC"]
* }
* ```
*
* If you wanted to change parameters on the `CLOUDWATCH_ALARM_ACTION_CHECK` complex rule you could pass it to the `complex_config_rules` variable:
*
* ```hcl
* module "aws_config" {
*   source = "git::https://github.com/moritzheiber/terraform-aws-core-modules//config"
*     
*   complex_config_rules = {
*     CLOUDWATCH_ALARM_ACTION_CHECK = {
*       alarmActionRequired            = "false"
*       insufficientDataActionRequired = "true"
*       okActionRequired               = "true"
*     }
*   }
* }
* ```
*
* For a list of available managed rules you can refer [to the AWS Config documentation](https://docs.aws.amazon.com/config/latest/developerguide/managed-rules-by-aws-config.html).
* As a rule of thumb:
* - **if they require no parameters** you can use either `enable_config_rules` or `disable_config_rules` to manage them.
* - **if they require parameters** you can use the `complex_config_rules` map to add them and their input parameters as a `identifier = { parameter = value }` map.
* 
* For both cases you need to use their _uppercase, snake case identifier_ (e.g. `autoscaling-capacity-rebalancing` becomes `AUTOSCALING_CAPACITY_REBALANCING`)
*
* ### Special cases
*
* For a few rules there is special treatment using variables:
*
* - `IAM_PASSWORD_POLICY`: See the `password_policy` variable
* - `IAM_USER_GROUP_MEMBERSHIP_CHECK`: See the `iam_user_groups` variable
* - `APPROVED_AMIS_BY_TAG`: See the `amis_by_tag_key_and_value_list` variable
* - `ACCESS_KEYS_ROTATED`: See the `max_access_key_age` variable
* - `DESIRED_INSTANCE_TYPE`: See the `desired_instance_types` variable (_Note: the identifier says `type` but this is **a list**_)
*
* You can disable any of these complex rules by simply unsetting the corresponding variable.
*/

locals {
  config_policy_arn        = "arn:aws:iam::aws:policy/service-role/AWSConfigRole"
  bucket_account_id        = length(var.bucket_account_id) > 0 ? var.bucket_account_id : data.aws_caller_identity.current.account_id
  aws_config_s3_bucket_arn = var.enable_lifecycle_management_for_s3 ? aws_s3_bucket.config_with_lifecycle[0].arn : aws_s3_bucket.config_without_lifecycle[0].arn

  simple_config_rules = setsubtract(
    var.enable_config_rules,
    var.disable_config_rules
  )

  complex_rules_password_policy = {
    IAM_PASSWORD_POLICY = {
      RequireUppercaseCharacters = var.password_policy["require_uppercase_chars"]
      RequireLowercaseCharacters = var.password_policy["require_lowercase_chars"]
      RequireSymbols             = var.password_policy["require_symbols"]
      RequireNumbers             = var.password_policy["require_numbers"]
      MinimumPasswordLength      = var.password_policy["minimum_password_length"]
      PasswordReusePrevention    = var.password_policy["password_reuse_prevention"]
      MaxPasswordAge             = var.password_policy["max_password_age"]
    }
  }

  complex_rules_group_membership = length(var.iam_user_groups) > 0 ? {
    IAM_USER_GROUP_MEMBERSHIP_CHECK = var.iam_user_groups
  } : {}

  complex_rules_approved_ami_tags = length(var.amis_by_tag_key_and_value_list) > 0 ? {
    APPROVED_AMIS_BY_TAG = {
      amisByTagKeyAndValue = var.amis_by_tag_key_and_value_list
    }
  } : {}

  complex_rules_access_key_rotation = length(var.max_access_key_age) > 0 ? {
    ACCESS_KEYS_ROTATED = {
      maxAccessKeyAge = var.max_access_key_age
    }
  } : {}

  complex_rules_desired_instance_type = length(var.desired_instance_types) > 0 ? {
    DESIRED_INSTANCE_TYPE = {
      maxAccessKeyAge = var.desired_instance_types
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

# KMS key for bucket encryption
resource "aws_kms_key" "s3_bucket_encryption" {
  description             = "This key is used to encrypt the S3 bucket for AWS Config"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

# S3 buckets
# tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "config_with_lifecycle" {
  count         = var.enable_lifecycle_management_for_s3 ? 1 : 0
  bucket_prefix = var.bucket_prefix
}

# tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "config_without_lifecycle" {
  count         = var.enable_lifecycle_management_for_s3 ? 0 : 1
  bucket_prefix = var.bucket_prefix

  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "enforce_encryption" {
  bucket = var.enable_lifecycle_management_for_s3 ? aws_s3_bucket.config_with_lifecycle[0].bucket : aws_s3_bucket.config_without_lifecycle[0].bucket


  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_bucket_encryption.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "deny_public_access" {
  bucket = var.enable_lifecycle_management_for_s3 ? aws_s3_bucket.config_with_lifecycle[0].bucket : aws_s3_bucket.config_without_lifecycle[0].bucket

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}

resource "aws_s3_bucket_acl" "acl" {
  bucket = var.enable_lifecycle_management_for_s3 ? aws_s3_bucket.config_with_lifecycle[0].bucket : aws_s3_bucket.config_without_lifecycle[0].bucket

  acl = "private"
}

resource "aws_s3_bucket_versioning" "versioning" {
  bucket = var.enable_lifecycle_management_for_s3 ? aws_s3_bucket.config_with_lifecycle[0].bucket : aws_s3_bucket.config_without_lifecycle[0].bucket

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
  s3_bucket_name = var.enable_lifecycle_management_for_s3 ? aws_s3_bucket.config_with_lifecycle[0].bucket : aws_s3_bucket.config_without_lifecycle[0].bucket

  s3_key_prefix = var.bucket_key_prefix

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

# Simple Config rules which just require the identifier of the rule
resource "aws_config_config_rule" "rule_simple" {
  for_each = local.simple_config_rules
  name     = lower(each.key)

  source {
    owner             = "AWS"
    source_identifier = each.key
  }

  depends_on = [aws_config_configuration_recorder.config]
}

# These are more complicated because they require more input
resource "aws_config_config_rule" "rule_complex" {
  for_each = local.complex_rules
  name     = lower(each.key)

  source {
    owner             = "AWS"
    source_identifier = each.key
  }

  input_parameters = jsonencode(each.value)

  depends_on = [aws_config_configuration_recorder.config]
}
