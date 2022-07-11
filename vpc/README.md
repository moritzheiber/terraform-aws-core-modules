
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