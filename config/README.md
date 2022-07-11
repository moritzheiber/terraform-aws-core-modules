<!-- BEGIN_TF_DOCS -->
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
<!-- END_TF_DOCS -->