
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