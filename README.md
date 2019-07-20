# AWS Core Modules

This is a collection of Terraform "core" modules I would consider to be building blocks of every reasonable AWS account setup.

## Available modules

- [config](#config)
- [vpc](#vpc)

## config

The module configures AWS Config to monitor your account for non-compliant resources for the following checks:

- **INSTANCES_IN_VPC**: All instances need to be started in a VPC (the default since years)
- **EC2_VOLUME_INUSE_CHECK**: All volumes need to be attached (otherwise they cost money for nothing)
- **EIP_ATTACHED**: All EIPs need to be attached (otherwise they cost money)
- **ENCRYPTED_VOLUMES**: All volumes in the account need to be encrypted
- **INCOMING_SSH_DISABLED**: No Security Group has port 22 open to the world
- **CLOUD_TRAIL_ENABLED**: CloudTrail is enabled in the account
- **CLOUDWATCH_ALARM_ACTION_CHECK**: You need to at least have an action for the state "Alarm" defined
- **IAM_GROUP_HAS_USERS_CHECK**: Every group in IAM needs to have users attached to it
- **IAM_PASSWORD_POLICY**: Account needs to have a password policy, with a certain complexity and it has to be enforced
- **IAM_USER_GROUP_MEMBERSHIP_CHECK**: A list of groups IAM users have to be a part of
- **IAM_USER_NO_POLICIES_CHECK**: None of your users should have policies attached to them directly, use groups/roles for that
- **ROOT_ACCOUNT_MFA_ENABLED**: Your root account needs to have MFA enabled
- **S3_BUCKET_PUBLIC_READ_PROHIBITED**: S3 buckets shouldn't be open to the public
- **S3_BUCKET_PUBLIC_WRITE_PROHIBITED**: S3 buckets shouldn't be publicly writable
- **S3_BUCKET_SSL_REQUESTS_ONLY**: S3 buckets must only allow TLS traffic (through bucket policies)
- **S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED**: S3 buckets must have SSE enabled
- **S3_BUCKET_VERSIONING_ENABLED**: S3 bucket versioning has to be enabled
- **EBS_OPTIMIZED_INSTANCE**: All instances run on EBS-optimized storage
- **ACCESS_KEYS_ROTATED**: All your access keys need to be rotated after a certain while
- **APPROVED_AMIS_BY_TAG**: Only allow AMIs with a certain tag for EC2 instances
- **AUTOSCALING_GROUP_ELB_HEALTHCHECK_REQUIRED**: AutoScalingGroups must be attached to an LB and have health checks enabled
- **DESIRED_INSTANCE_TYPE**: Only allow for certain instance types to be used
- **RDS_INSTANCE_PUBLIC_ACCESS_CHECK**: RDS instances must not be publicly accessible
- **RDS_SNAPSHOTS_PUBLIC_PROHIBITED**: RDS snapshots must not be public
- **IAM_POLICY_NO_STATEMENTS_WITH_ADMIN_ACCESS**: None of your policies allow for administrative privilege escalation
- **IAM_ROOT_ACCESS_KEY_CHECK**: Your root account must not have any security credentials attached to it

Some of them can receive extra parameters. See a table reference below.

### Example

Add the following statement to your `variables.tf` to use the `config` module in version `v0.2.0`:

```terraform
module "aws_config" {
  source = "git::https://github.com/moritzheiber/terraform-aws-core-modules.git//config?ref=v0.2.0"

  # Optional, defaults to "aws-config"
  bucket_name_prefix = "my-aws-config-bucket"
  # Optional, you should disable it for testing purposes, otherwise you will have trouble removing the S3 bucket again
  enable_lifecycle_management_for_s3 = false
}
```

and run `terraform init` to download the required module files.

### Parameters

#### Optional

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| **`bucket_prefix`** | string | `aws-config` | Prefix for the S3 bucket AWS Config Recorder writes to |
| **`bucket_key_prefix`** | string | `aws_config` | Prefix of the keys AWS Config writes to inside the bucket |
| **`config_recorder_name`** | string | `config` | The name of the recorder for AWS Config |
| **`config_delivery_channel_name`** | string | `conifg` | The name of the delivery channel for AWS Config |
| **`iam_role_name`** | string | `config` | The name of the IAM role created for delegating permissions to AWS Config |
| **`bucket_account_id`** | string | `""` (will use own S3 bucket)| The AWS account ID the S3 bucket lives in that AWS Config is writing its records to. Defaults to the ID of the current account |
| **`delivery_frequency`** | string | `Three_Hours` | The frequency at which AWS Config delivers its recorded findings to S3 |
| **`password_policy`** | map(string) | `{}` | A map of values describing the password policy parameters AWS Config is looking for |
| **`iam_user_groups`** | list(string) | `[]` | A list of mandatory groups for IAM users |
| **`max_access_key_age`** | string | "90" | The maximum amount of days an access key can live without being rotated |
| **`enable_lifecycle_management_for_s3`** | bool | `true` | Whether or not to enable lifecycle management for the S3 bucket AWS Config writes to (should only be disabled for testing purposes) |
| **`amis_by_tag_key_and_value_list`** | list(string) | `[]` | Required AMI tags for EC2 instances |
| **`desired_instance_types`** | set(string) | `[]` | A set of comma-delimited instance types |

## vpc

The module builds a VPC with the default CIDR range of `10.0.0.0/16`, three subnets a "public" configuration (attached and routed to an AWS Internet Gateway) and three subnets in a "private" configuration (attached and routed through three separate AWS NAT Gateways). You can specify the following attributes:

### Example

Add the following statement to your `variables.tf` to use the `vpc` module in version `v0.2.0`:

```terraform
module "core_vpc" {
  source = "git::https://github.com/moritzheiber/terraform-aws-core-modules.git//vpc?ref=v0.2.0"

  resource_tag = "my_aws_account"
}
```

and run `terraform init` to download the required module files.

### Parameters

#### Required
| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| **`resource_tag`**| string| | A common tag for all the VPC resources created |

#### Optional

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| **`vpc_name`** | string | `core_vpc` | The name of the VPC |
| **`vpc_cidr_range`** | string | `10.0.0.0/16` (enough for 65534 IPv4 addresses)) | CIDR range for the VPC |
| **`public_subnet_cidrs`** | list | Automatically calculated subnet blocks | CIDR ranges for the public subnets. You have to specify at least as many subnets as there are Availability Zones in the region you are deploying into (probably 3) |
| **`private_subnet_cidrs`** | list | Automatically calculated subnet blocks | CIDR ranges for the private subnets. You have to specify at least as many subnets as there are Availability Zones in the region you are deploying into (probably 3) |
| **`public_subnet_size`** | number | `6` (that's a /22 with 1024 addresses) | CIDR size for each public subnet |
| **`private_subnet_size`** | number | `6` (that's a /22, with 1024 addresses) | CIDR size of each private subnet |
| **`private_subnet_offset`** | number | `32` (private subnets start at 10.0.128.0/22 with the default settings) | Offset between public and private subnets |
| **`public_subnet_prefix`** | string | `${var.vpc_name}_public_subnet` | Prefix of the public subnets |
| **`private_subnet_prefix`** | string | `${var.vpc_name}_private_subnet` | Prefix of the private subnets |
| **`enable_dns_support`** | bool | `true` | Whether or not to enable VPC DNS support |
| **`enable_dns_hostnames`** | bool | `true` | Whether or not to enable VPC DNS hostnames |
