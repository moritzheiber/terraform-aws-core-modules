
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
| <a name="input_additional_admin_groups"></a> [additional\_admin\_groups](#input\_additional\_admin\_groups) | A list of additional groups to create associated with administrative privileges | `list(string)` | `[]` | no |
| <a name="input_additional_user_groups"></a> [additional\_user\_groups](#input\_additional\_user\_groups) | A list of additional groups to create associated with regular users | `list(string)` | `[]` | no |
| <a name="input_admin_group_name"></a> [admin\_group\_name](#input\_admin\_group\_name) | The name of the initial group created for administrators | `string` | `"admins"` | no |
| <a name="input_admin_multi_factor_auth_age"></a> [admin\_multi\_factor\_auth\_age](#input\_admin\_multi\_factor\_auth\_age) | The amount of time (in minutes) for a admin session to be valid | `number` | `60` | no |
| <a name="input_iam_account_alias"></a> [iam\_account\_alias](#input\_iam\_account\_alias) | A globally unique, human-readable identifier for your AWS account | `string` | `null` | no |
| <a name="input_iam_users"></a> [iam\_users](#input\_iam\_users) | A list of maps of users and their groups. Default is to create no users. | `map(map(list(string)))` | `{}` | no |
| <a name="input_password_policy"></a> [password\_policy](#input\_password\_policy) | A map of password policy parameters you want to set differently from the defaults | `map(string)` | <pre>{<br>  "max_password_age": "90",<br>  "minimum_password_length": "32",<br>  "password_reuse_prevention": "5",<br>  "require_lowercase_chars": "true",<br>  "require_numbers": "true",<br>  "require_symbols": "true",<br>  "require_uppercase_chars": "true"<br>}</pre> | no |
| <a name="input_resource_admin_role_name"></a> [resource\_admin\_role\_name](#input\_resource\_admin\_role\_name) | The name of the administrator role one is supposed to assume in the resource account | `string` | `"resource-admin"` | no |
| <a name="input_resource_user_role_name"></a> [resource\_user\_role\_name](#input\_resource\_user\_role\_name) | The name of the user role one is supposed to assume in the resource account | `string` | `"resource-user"` | no |
| <a name="input_resources_account_id"></a> [resources\_account\_id](#input\_resources\_account\_id) | The account ID of the AWS account you want to start resources in | `string` | `""` | no |
| <a name="input_user_group_name"></a> [user\_group\_name](#input\_user\_group\_name) | The name of the initial group created for users | `string` | `"users"` | no |
| <a name="input_user_multi_factor_auth_age"></a> [user\_multi\_factor\_auth\_age](#input\_user\_multi\_factor\_auth\_age) | The amount of time (in minutes) for a user session to be valid | `number` | `240` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_admin_group_names"></a> [admin\_group\_names](#output\_admin\_group\_names) | The names of the admin groups |
| <a name="output_user_group_names"></a> [user\_group\_names](#output\_user\_group\_names) | The name of the user groups |