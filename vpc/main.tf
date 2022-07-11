/**
*
* ## vpc
* 
* This module builds a VPC with the default CIDR range of `10.0.0.0/16`, three subnets in a "public" configuration (attached to and routed through an AWS Internet Gateway) and three subnets in a "private" configuration (attached to and routed through three separate AWS NAT Gateways):
* 
* ![AWS VPC illustration](https://raw.githubusercontent.com/moritzheiber/terraform-aws-core-modules/main/files/aws_vpc.png)
* 
* ### Usage example
* 
* Add the following statement to your `variables.tf` to use the `vpc` module:
* 
* ```hcl
* module "core_vpc" {
*   source = "git::https://github.com/moritzheiber/terraform-aws-core-modules.git//vpc"
* 
*   tags = {
*     Resource    = "my_team_name"
*     Cost_Center = "my_billing_tag"
*   }
* }
* ```
* 
* and run `terraform init` to download the required module files.
* 
* **All created subnets will have a tag attached to them which specifies their scope** (i.e. "public" for public subnets and "private" for private subnets) which you can use to filter for the right networks using Terraform data sources:
* 
* ```hcl
* data "aws_vpc" "core" {
* tags = {
*     # `core_vpc` is the default, the variable is `vpc_name`
*     Name = "core_vpc"
*   }
* }
* 
* data "aws_subnets" "public" {
*   filter {
*     name   = "vpc-id"
*     values = [data.aws_vpc.core.id]
*   }
* 
*   tags = {
*     Scope = "Public"
*   }
* }
* 
* data "aws_subnets" "public" {
*   filter {
*     name   = "vpc-id"
*     values = [data.aws_vpc.core.id]
*   }
* 
*   tags = {
*     Scope = "Private"
*   }
* }
* ```
* 
* The result is a list of subnet IDs, either in the public or private VPC zone, you can use to create other resources such as Load Balancers or AutoScalingGroups.
*
*/

locals {
  public_subnet_prefix         = length(var.public_subnet_prefix) > 0 ? var.public_subnet_prefix : "${var.vpc_name}_public_subnet"
  private_subnet_prefix        = length(var.private_subnet_prefix) > 0 ? var.private_subnet_prefix : "${var.vpc_name}_private_subnet"
  number_of_availability_zones = length(data.aws_availability_zones.available.names)
  public_subnet_info           = [for az in range(local.number_of_availability_zones) : { name = "public_az${az}", new_bits = var.public_subnet_size }]
  private_subnet_info          = [for az in range(local.number_of_availability_zones) : { name = "private_az${az}", new_bits = var.private_subnet_size }]
  network_separation           = [{ name = null, new_bits = var.private_subnet_offset }]
  networks                     = concat(local.public_subnet_info, local.network_separation, local.private_subnet_info)
  public_subnets               = [for name, cidr in module.subnets.network_cidr_blocks : cidr if length(regexall("^public_.*", name)) > 0]
  private_subnets              = [for name, cidr in module.subnets.network_cidr_blocks : cidr if length(regexall("^private_.*", name)) > 0]
}

module "subnets" {
  source = "hashicorp/subnets/cidr"

  base_cidr_block = var.vpc_cidr_range
  networks        = local.networks
}

# VPC
resource "aws_vpc" "core" {
  cidr_block           = var.vpc_cidr_range
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge({ Name = var.vpc_name }, var.tags)
}

# Public subnets
resource "aws_subnet" "public_subnet" {
  count                   = local.number_of_availability_zones
  vpc_id                  = aws_vpc.core.id
  cidr_block              = local.public_subnets[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge({
    Name = "${local.public_subnet_prefix}_${replace(
      data.aws_availability_zones.available.names[count.index],
      "-",
      "_",
    )}"
    Scope = "public" },
  var.tags)
}

# Private subnets
resource "aws_subnet" "private_subnet" {
  count                   = local.number_of_availability_zones
  vpc_id                  = aws_vpc.core.id
  cidr_block              = local.private_subnets[count.index]
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = merge({
    Name = "${local.private_subnet_prefix}_${replace(
      data.aws_availability_zones.available.names[count.index],
      "-",
      "_",
    )}"
    Scope = "private" },
  var.tags)
}

# IGW - Internet Gateway
resource "aws_internet_gateway" "core_igw" {
  vpc_id = aws_vpc.core.id

  tags = merge({
    Name = "${var.vpc_name}_igw"
  }, var.tags)
}

# EIPs for NAT Gateways
resource "aws_eip" "core_nat_gw_eip" {
  count = local.number_of_availability_zones
  vpc   = true

  tags = merge({
    Name = "${var.vpc_name}_nat_gw_eip_${replace(
      data.aws_availability_zones.available.names[count.index],
      "-",
      "_",
    )}"
  }, var.tags)
}

# NAT Gateways for private subnets
resource "aws_nat_gateway" "core_nat_gw" {
  count         = local.number_of_availability_zones
  subnet_id     = aws_subnet.public_subnet[count.index].id
  allocation_id = aws_eip.core_nat_gw_eip[count.index].id

  tags = merge({
    Name = "${var.vpc_name}_nat_gw_${replace(
      data.aws_availability_zones.available.names[count.index],
      "-",
      "_",
    )}"
  }, var.tags)
}

# Route tables for public/private subnets
resource "aws_route_table" "core_main_route_table" {
  vpc_id = aws_vpc.core.id

  tags = merge({
    Name = "${var.vpc_name}_main_route_table_name"
  }, var.tags)
}

resource "aws_route_table" "core_private_route_table" {
  count  = local.number_of_availability_zones
  vpc_id = aws_vpc.core.id
  route  = []

  tags = merge({
    Name = "${var.vpc_name}_private_route_table_${replace(
      data.aws_availability_zones.available.names[count.index],
      "-",
      "_",
    )}"
  }, var.tags)
}

# Default public route through the IGW
resource "aws_route" "core_main_route_table_public_default_route" {
  route_table_id         = aws_route_table.core_main_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.core_igw.id
}

# Default private route through the NAT gateways
resource "aws_route" "core_private_route_table_default_route" {
  count                  = local.number_of_availability_zones
  route_table_id         = aws_route_table.core_private_route_table[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.core_nat_gw[count.index].id
}

resource "aws_route_table_association" "core_private_route_table_association" {
  count          = local.number_of_availability_zones
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.core_private_route_table[count.index].id
}
