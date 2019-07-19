# AWS Core Modules

This is a collection of Terraform "core" modules I would consider to be building blocks of every reasonable AWS account setup.

## Available modules

- [vpc](#vpc)

## vpc

The module builds a VPC with the default CIDR range of `10.0.0.0/16`, three subnets a "public" configuration (attached and routed to an AWS Internet Gateway) and three subnets in a "private" configuration (attached and routed through three separate AWS NAT Gateways). You can specify the following attributes:

### Example

Add the following statement to your `variables.tf` to use the `vpc` module in version `v0.1.0`:

```terraform
module "core_vpc" {
  source = "git::https://github.com/moritzheiber/terraform-aws-core-modules.git//vpc?ref=v0.1.0"

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
