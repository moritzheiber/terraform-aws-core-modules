<!-- BEGIN_TF_DOCS -->
# AWS Core Modules

This is a collection of Terraform "core" modules I would consider to be building blocks of every reasonable AWS account setup.
Please refer to to the [AWS Kickstarter](https://github.com/moritzheiber/aws-kickstarter) to see their application.

Contributions are more than welcome and encouraged!

## Available modules
- [config](#config)
- [iam-resources](#iam-resources)
- [iam-users](#iam-users)
- [vpc](#vpc)

## Config

The module configures AWS Config to monitor your account for non-compliant resources.
You can freely choose which checks to use or discard by modifying the `enable_config_rules`, `disable_config_rules` and `complex_config_rules` variables.

As an example, if you'd wish to enable `AUTOSCALING_CAPACITY_REBALANCING` and disable the `INSTANCES_IN_VPC` check, which is enabled by default, you could use the following code:

```hcl
module "aws_config" {
    source = "git::https://github.com/moritzheiber/terraform-aws-core-modules//config"

    enable_simple_rules = ["AUTOSCALING_CAPACITY_REBALANCING"]
    disable_simple_rules = ["INSTANCE_IN_VPC"]
}
```

If you wanted to change parameters on the `CLOUDWATCH_ALARM_ACTION_CHECK` complex rule you could pass it to the `complex_config_rules` variable:

```hcl
module "aws_config" {
  source = "git::https://github.com/moritzheiber/terraform-aws-core-modules//config"

  complex_config_rules = {
    CLOUDWATCH_ALARM_ACTION_CHECK = {
      alarmActionRequired            = "false"
      insufficientDataActionRequired = "true"
      okActionRequired               = "true"
    }
  }
}
```

For a list of available managed rules you can refer [to the AWS Config documentation](https://docs.aws.amazon.com/config/latest/developerguide/managed-rules-by-aws-config.html).
As a rule of thumb:
- **if they require no parameters** you can use either `enable_config_rules` or `disable_config_rules` to manage them.
- **if they require parameters** you can use the `complex_config_rules` map to add them and their input parameters as a `identifier = { parameter = value }` map.

For both cases you need to use their _uppercase, snake case identifier_ (e.g. `autoscaling-capacity-rebalancing` becomes `AUTOSCALING_CAPACITY_REBALANCING`)

### Special cases

For a few rules there is special treatment using variables:

- `IAM_PASSWORD_POLICY`: See the `password_policy` variable
- `IAM_USER_GROUP_MEMBERSHIP_CHECK`: See the `iam_user_groups` variable
- `APPROVED_AMIS_BY_TAG`: See the `amis_by_tag_key_and_value_list` variable
- `ACCESS_KEYS_ROTATED`: See the `max_access_key_age` variable
- `DESIRED_INSTANCE_TYPE`: See the `desired_instance_types` variable (\_Note: the identifier says `type` but this is **a list**\_)

You can disable any of these complex rules by simply unsetting the corresponding variable.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_amis_by_tag_key_and_value_list"></a> [amis\_by\_tag\_key\_and\_value\_list](#input\_amis\_by\_tag\_key\_and\_value\_list) | Required AMI tags for EC2 instances | `list(string)` | `[]` | no |
| <a name="input_bucket_account_id"></a> [bucket\_account\_id](#input\_bucket\_account\_id) | The AWS account ID the S3 bucket lives in that AWS Config is writing its records to. Defaults to the ID of the current account | `string` | `""` | no |
| <a name="input_bucket_key_prefix"></a> [bucket\_key\_prefix](#input\_bucket\_key\_prefix) | The prefix of the keys AWS Config writes to | `string` | `"aws_config"` | no |
| <a name="input_bucket_prefix"></a> [bucket\_prefix](#input\_bucket\_prefix) | The prefix for the S3 bucket AWS Config Recorder writes to | `string` | `"aws-config"` | no |
| <a name="input_complex_config_rules"></a> [complex\_config\_rules](#input\_complex\_config\_rules) | A range of more complex Config rules you wish to have applied. They usually carry input parameters. | `map(map(string))` | <pre>{<br>  "CLOUDWATCH_ALARM_ACTION_CHECK": {<br>    "alarmActionRequired": "true",<br>    "insufficientDataActionRequired": "false",<br>    "okActionRequired": "false"<br>  }<br>}</pre> | no |
| <a name="input_config_delivery_channel_name"></a> [config\_delivery\_channel\_name](#input\_config\_delivery\_channel\_name) | The name of the delivery channel for AWS Config | `string` | `"config"` | no |
| <a name="input_config_recorder_name"></a> [config\_recorder\_name](#input\_config\_recorder\_name) | The name of the recorder for AWS Config | `string` | `"config"` | no |
| <a name="input_delivery_frequency"></a> [delivery\_frequency](#input\_delivery\_frequency) | The frequency at which AWS Config delivers its recorded findings to S3 | `string` | `"Three_Hours"` | no |
| <a name="input_desired_instance_types"></a> [desired\_instance\_types](#input\_desired\_instance\_types) | A string of comma-delimited instance types | `set(string)` | `[]` | no |
| <a name="input_disable_config_rules"></a> [disable\_config\_rules](#input\_disable\_config\_rules) | A set with simple rules you wish to disable. Otherwise all the rules are applied by default. | `set(string)` | `[]` | no |
| <a name="input_enable_config_rules"></a> [enable\_config\_rules](#input\_enable\_config\_rules) | A set with simple rules you wish to enable. The defaults are pretty solid. If you wish to only disable a few rules take a look at the 'disable\_config\_rules' variable. | `set(string)` | <pre>[<br>  "INSTANCES_IN_VPC",<br>  "EC2_VOLUME_INUSE_CHECK",<br>  "EIP_ATTACHED",<br>  "ENCRYPTED_VOLUMES",<br>  "INCOMING_SSH_DISABLED",<br>  "CLOUD_TRAIL_ENABLED",<br>  "IAM_GROUP_HAS_USERS_CHECK",<br>  "IAM_USER_NO_POLICIES_CHECK",<br>  "ROOT_ACCOUNT_MFA_ENABLED",<br>  "S3_BUCKET_PUBLIC_READ_PROHIBITED",<br>  "S3_BUCKET_PUBLIC_WRITE_PROHIBITED",<br>  "S3_BUCKET_SSL_REQUESTS_ONLY",<br>  "S3_BUCKET_SERVER_SIDE_ENCRYPTION_ENABLED",<br>  "S3_BUCKET_VERSIONING_ENABLED",<br>  "EBS_OPTIMIZED_INSTANCE",<br>  "AUTOSCALING_GROUP_ELB_HEALTHCHECK_REQUIRED",<br>  "RDS_INSTANCE_PUBLIC_ACCESS_CHECK",<br>  "RDS_SNAPSHOTS_PUBLIC_PROHIBITED",<br>  "IAM_POLICY_NO_STATEMENTS_WITH_ADMIN_ACCESS",<br>  "IAM_ROOT_ACCESS_KEY_CHECK"<br>]</pre> | no |
| <a name="input_enable_lifecycle_management_for_s3"></a> [enable\_lifecycle\_management\_for\_s3](#input\_enable\_lifecycle\_management\_for\_s3) | Whether or not to enable lifecycle management for the S3 bucket AWS Config writes to | `bool` | `false` | no |
| <a name="input_iam_role_name"></a> [iam\_role\_name](#input\_iam\_role\_name) | The name of the IAM role created for delegating permissions to AWS Config | `string` | `"config"` | no |
| <a name="input_iam_user_groups"></a> [iam\_user\_groups](#input\_iam\_user\_groups) | A list of mandatory groups for IAM users | `list(string)` | `[]` | no |
| <a name="input_lifecycle_bucket_expiration"></a> [lifecycle\_bucket\_expiration](#input\_lifecycle\_bucket\_expiration) | The number of days after which artifacts in the Config S3 bucket are expiring | `number` | `365` | no |
| <a name="input_max_access_key_age"></a> [max\_access\_key\_age](#input\_max\_access\_key\_age) | The maximum amount of days an access key can live without being rotated | `string` | `"90"` | no |
| <a name="input_password_policy"></a> [password\_policy](#input\_password\_policy) | A map of values describing the password policy parameters AWS Config is looking for | `map(string)` | <pre>{<br>  "max_password_age": "90",<br>  "minimum_password_length": "32",<br>  "password_reuse_prevention": "5",<br>  "require_lowercase_chars": "true",<br>  "require_numbers": "true",<br>  "require_symbols": "true",<br>  "require_uppercase_chars": "true"<br>}</pre> | no |
| <a name="input_s3_kms_sse_encryption_key_arn"></a> [s3\_kms\_sse\_encryption\_key\_arn](#input\_s3\_kms\_sse\_encryption\_key\_arn) | The ARN for the KMS key to use for S3 server-side bucket encryption. If none if specified the module creates a KMS key for customer managed encryption. | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_config_s3_bucket_arn"></a> [config\_s3\_bucket\_arn](#output\_config\_s3\_bucket\_arn) | The ARN of the S3 bucket AWS Config writes its findings into |


## iam-users

A module to configure the "users" account modeled after a common security principle of separating users from resource accounts through a MFA-enabled role-assumption bridge:

![AWS IAM setup illustration](https://raw.githubusercontent.com/moritzheiber/terraform-aws-core-modules/main/files/aws_iam_setup.png)

These strict separation of privileges follow [an article I wrote a while ago](https://www.thoughtworks.com/insights/blog/using-aws-security-first-class-citizen).
You can also create IAM users and IAM groups with this module and assign the users to specific groups. The module will create two default groups, one for admins and users, which you can disable by setting the `admin_group_name` and `user_group_name` to an empty string.

Creating additional users is done by passing a map called `users` to the module, with a group mapping attached to them (the best practice is to never have users live "outside" of groups).

```hcl
variable "iam_users" {
  type = map(map(set(string)))
  default = {
    my_user = {
      groups = ["admins"]
    }
  }
}

module "iam_users" {
  source            = "git::https://github.com/moritzheiber/terraform-aws-core-modules.git//iam-users"

  iam_account_alias = "my_unique_alias"
  iam_users = var.iam_users
}
```

This will run the module and create all the necessary permissions along with a user belonging to the `admins` groups.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_iam_account_alias"></a> [iam\_account\_alias](#input\_iam\_account\_alias) | A globally unique, human-readable identifier for your AWS account | `string` | n/a | yes |
| <a name="input_additional_admin_groups"></a> [additional\_admin\_groups](#input\_additional\_admin\_groups) | A list of additional groups to create associated with administrative privileges | `list(string)` | `[]` | no |
| <a name="input_additional_user_groups"></a> [additional\_user\_groups](#input\_additional\_user\_groups) | A list of additional groups to create associated with regular users | `list(string)` | `[]` | no |
| <a name="input_admin_group_name"></a> [admin\_group\_name](#input\_admin\_group\_name) | The name of the initial group created for administrators | `string` | `"admins"` | no |
| <a name="input_iam_users"></a> [iam\_users](#input\_iam\_users) | A list of maps of users and their groups. Default is to create no users. | `map(map(list(string)))` | `{}` | no |
| <a name="input_multi_factor_auth_age"></a> [multi\_factor\_auth\_age](#input\_multi\_factor\_auth\_age) | The amount of time (in seconds) for a user session to be valid | `string` | `"14400"` | no |
| <a name="input_password_policy"></a> [password\_policy](#input\_password\_policy) | A map of password policy parameters you want to set differently from the defaults | `map(string)` | <pre>{<br>  "max_password_age": "90",<br>  "minimum_password_length": "32",<br>  "password_reuse_prevention": "5",<br>  "require_lowercase_chars": "true",<br>  "require_numbers": "true",<br>  "require_symbols": "true",<br>  "require_uppercase_chars": "true"<br>}</pre> | no |
| <a name="input_resource_admin_role_name"></a> [resource\_admin\_role\_name](#input\_resource\_admin\_role\_name) | The name of the administrator role one is supposed to assume in the resource account | `string` | `"resource-admin"` | no |
| <a name="input_resource_user_role_name"></a> [resource\_user\_role\_name](#input\_resource\_user\_role\_name) | The name of the user role one is supposed to assume in the resource account | `string` | `"resource-user"` | no |
| <a name="input_resources_account_id"></a> [resources\_account\_id](#input\_resources\_account\_id) | The account ID of the AWS account you want to start resources in | `string` | `""` | no |
| <a name="input_set_iam_account_alias"></a> [set\_iam\_account\_alias](#input\_set\_iam\_account\_alias) | Whether or not to set the account alias (useful to set to false when iam-users and iam-resources module are being deployed into the same account) | `bool` | `true` | no |
| <a name="input_user_group_name"></a> [user\_group\_name](#input\_user\_group\_name) | The name of the initial group created for users | `string` | `"users"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_admin_group_names"></a> [admin\_group\_names](#output\_admin\_group\_names) | The names of the admin groups |
| <a name="output_user_group_names"></a> [user\_group\_names](#output\_user\_group\_names) | The name of the user groups |


## iam-resources

A module to configure the "resources" account modelled after the common security principle of separating users from resource accounts through a MFA-enabled role-assumption bridge.
Please see the [iam-users](https://github.com/moritzheiber/terraform-aws-core-modules/tree/main/iam-users) module for further explanation. It is generally assumed that this module isn't deployed on its own.

### Usage example
```hcl
module "iam_resources" {
  source            = "git::https://github.com/moritzheiber/terraform-aws-core-modules.git//iam-resources"
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_access_role_name"></a> [admin\_access\_role\_name](#input\_admin\_access\_role\_name) | Name of the admin role | `string` | `"resource-admin"` | no |
| <a name="input_admin_multi_factor_auth_age"></a> [admin\_multi\_factor\_auth\_age](#input\_admin\_multi\_factor\_auth\_age) | The amount of time (in minutes) for a admin session to be valid | `number` | `60` | no |
| <a name="input_iam_account_alias"></a> [iam\_account\_alias](#input\_iam\_account\_alias) | A globally unique identifier, human-readable for your AWS account | `string` | `null` | no |
| <a name="input_user_access_role_name"></a> [user\_access\_role\_name](#input\_user\_access\_role\_name) | Name of the user role | `string` | `"resource-user"` | no |
| <a name="input_user_multi_factor_auth_age"></a> [user\_multi\_factor\_auth\_age](#input\_user\_multi\_factor\_auth\_age) | The amount of time (in minutes) for a user session to be valid | `number` | `240` | no |
| <a name="input_users_account_id"></a> [users\_account\_id](#input\_users\_account\_id) | The account ID of where the users are living in | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_resource_admin_role_arn"></a> [resource\_admin\_role\_arn](#output\_resource\_admin\_role\_arn) | The ARN of the role users are able to assume to attain admin privileges |
| <a name="output_resource_admin_role_name"></a> [resource\_admin\_role\_name](#output\_resource\_admin\_role\_name) | The name of the role users are able to assume to attain admin privileges |
| <a name="output_resource_user_role_arn"></a> [resource\_user\_role\_arn](#output\_resource\_user\_role\_arn) | The ARN of the role users are able to assume to attain user privileges |
| <a name="output_resource_user_role_name"></a> [resource\_user\_role\_name](#output\_resource\_user\_role\_name) | The name of the role users are able to assume to attain user privileges |


## vpc

This module builds a VPC with the default CIDR range of `10.0.0.0/16`, three subnets in a "public" configuration (attached to and routed through an AWS Internet Gateway) and three subnets in a "private" configuration (attached to and routed through three separate AWS NAT Gateways):

![AWS VPC illustration](https://raw.githubusercontent.com/moritzheiber/terraform-aws-core-modules/main/files/aws_vpc.png)

### Usage example

Add the following statement to your `variables.tf` to use the `vpc` module:

```hcl
module "core_vpc" {
  source = "git::https://github.com/moritzheiber/terraform-aws-core-modules.git//vpc"

  tags = {
    Resource    = "my_team_name"
    Cost_Center = "my_billing_tag"
  }
}
```

and run `terraform init` to download the required module files.

**All created subnets will have a tag attached to them which specifies their scope** (i.e. "public" for public subnets and "private" for private subnets) which you can use to filter for the right networks using Terraform data sources:

```hcl
data "aws_vpc" "core" {
tags = {
    # `core_vpc` is the default, the variable is `vpc_name`
    Name = "core_vpc"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.core.id]
  }

  tags = {
    Scope = "Public"
  }
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.core.id]
  }

  tags = {
    Scope = "Private"
  }
}
```

The result is a list of subnet IDs, either in the public or private VPC zone, you can use to create other resources such as Load Balancers or AutoScalingGroups.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_enable_dns_hostnames"></a> [enable\_dns\_hostnames](#input\_enable\_dns\_hostnames) | Whether or not to enable VPC DNS hostname support | `bool` | `true` | no |
| <a name="input_enable_dns_support"></a> [enable\_dns\_support](#input\_enable\_dns\_support) | Whether or not to enable VPC DNS support | `bool` | `true` | no |
| <a name="input_private_subnet_offset"></a> [private\_subnet\_offset](#input\_private\_subnet\_offset) | The amount of IP space between the public and the private subnet | `number` | `2` | no |
| <a name="input_private_subnet_prefix"></a> [private\_subnet\_prefix](#input\_private\_subnet\_prefix) | The prefix to attach to the name of the private subnets | `string` | `""` | no |
| <a name="input_private_subnet_size"></a> [private\_subnet\_size](#input\_private\_subnet\_size) | The size of the private subnet (default: 1022 usable addresses) | `number` | `6` | no |
| <a name="input_public_subnet_prefix"></a> [public\_subnet\_prefix](#input\_public\_subnet\_prefix) | The prefix to attach to the name of the public subnets | `string` | `""` | no |
| <a name="input_public_subnet_size"></a> [public\_subnet\_size](#input\_public\_subnet\_size) | The size of the public subnet (default: 1022 usable addresses) | `number` | `6` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to apply to all VPC resources | `map(string)` | `{}` | no |
| <a name="input_vpc_cidr_range"></a> [vpc\_cidr\_range](#input\_vpc\_cidr\_range) | The IP address space to use for the VPC | `string` | `"10.0.0.0/16"` | no |
| <a name="input_vpc_name"></a> [vpc\_name](#input\_vpc\_name) | The name of the VPC | `string` | `"core_vpc"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | A list of private subnet IDs |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | A list of public subnet IDs |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The ID of the created VPC |
<!-- END_TF_DOCS -->