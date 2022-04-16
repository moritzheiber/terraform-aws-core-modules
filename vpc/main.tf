
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
