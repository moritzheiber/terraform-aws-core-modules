variable "bucket_prefix" {
  type        = string
  description = "The prefix for the S3 bucket AWS Config Recorder writes to"
  default     = "aws-config"
}

variable "bucket_key_prefix" {
  type        = string
  description = "The prefix of the keys AWS Config writes to"
  default     = "aws_config"
}

variable "config_recorder_name" {
  type        = string
  description = "The name of the recorder for AWS Config"
  default     = "config"
}

variable "config_delivery_channel_name" {
  type        = string
  description = "The name of the delivery channel for AWS Config"
  default     = "config"
}

variable "iam_role_name" {
  type        = string
  description = "The name of the IAM role created for delegating permissions to AWS Config"
  default     = "config"
}

variable "bucket_account_id" {
  type        = string
  description = "The AWS account ID the S3 bucket lives in that AWS Config is writing its records to. Defaults to the ID of the current account"
  default     = ""
}

variable "delivery_frequency" {
  type        = string
  description = "The frequency at which AWS Config delivers its recorded findings to S3"
  default     = "Three_Hours"
}

# see https://docs.aws.amazon.com/config/latest/developerguide/iam-password-policy.html
variable "password_policy" {
  type        = map(string)
  description = "A map of values describing the password policy parameters AWS Config is looking for"
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

variable "iam_user_groups" {
  type        = list(string)
  description = "A list of mandatory groups for IAM users"
  default     = []
}

variable "max_access_key_age" {
  type        = string
  description = "The maximum amount of days an access key can live without being rotated"
  default     = "90"
}

variable "enable_lifecycle_management_for_s3" {
  type        = bool
  description = "Whether or not to enable lifecycle management for the S3 bucket AWS Config writes to"
  default     = false
}

variable "lifecycle_bucket_expiration" {
  type        = number
  description = "The number of days after which artifacts in the Config S3 bucket are expiring"
  default     = 365
}

variable "amis_by_tag_key_and_value_list" {
  type        = list(string)
  description = "Required AMI tags for EC2 instances"
  default     = []
}

variable "desired_instance_types" {
  type        = set(string)
  description = "A string of comma-delimited instance types"
  default     = []
}

variable "s3_kms_sse_encryption_key_arn" {
  type        = string
  description = "The ARN for the KMS key to use for S3 server-side bucket encryption. If none if specified the module creates a KMS key for customer managed encryption."
  default     = ""
}

variable "enable_config_rules" {
  type        = set(string)
  description = "A set with simple rules you wish to enable. The defaults are pretty solid. If you wish to only disable a few rules take a look at the 'disable_config_rules' variable."
  default = [
    "INSTANCES_IN_VPC",
    "EC2_VOLUME_INUSE_CHECK",
    "EIP_ATTACHED",
    "ENCRYPTED_VOLUMES",
    "INCOMING_SSH_DISABLED",
    "CLOUD_TRAIL_ENABLED",
    "IAM_GROUP_HAS_USERS_CHECK",
    "IAM_USER_NO_POLICIES_CHECK",
    "ROOT_ACCOUNT_MFA_ENABLED",
    "S3_BUCKET_PUBLIC_READ_PROHIBITED",
    "S3_BUCKET_PUBLIC_WRITE_PROHIBITED",
    "S3_BUCKET_SSL_REQUESTS_ONLY",
    "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED",
    "S3_BUCKET_VERSIONING_ENABLED",
    "EBS_OPTIMIZED_INSTANCE",
    "AUTOSCALING_GROUP_ELB_HEALTHCHECK_REQUIRE",
    "RDS_INSTANCE_PUBLIC_ACCESS_CHECK",
    "RDS_SNAPSHOTS_PUBLIC_PROHIBITED",
    "IAM_POLICY_NO_STATEMENTS_WITH_ADMIN_ACCESS",
    "IAM_ROOT_ACCESS_KEY_CHECK"
  ]
}

variable "disable_config_rules" {
  type        = set(string)
  description = "A set with simple rules you wish to disable. Otherwise all the rules are applied by default."
  default     = []
}

variable "complex_config_rules" {
  type        = map(object({ owner = string, input_parameters = any }))
  description = "A range of more complex Config rules you wish to have applied. They usually carry input parameters."
  default = {
    CLOUDWATCH_ALARM_ACTION_CHECK = {
      alarmActionRequired            = "true"
      insufficientDataActionRequired = "false"
      okActionRequired               = "false"
    }
  }
}
