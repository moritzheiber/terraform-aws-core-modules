# VPC

resource "aws_vpc" "core" {
  cidr_block           = var.vpc_cidr_range
  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = {
    Name     = var.vpc_name
    Resource = var.resource_tag
  }
}

# Public subnets
resource "aws_subnet" "public_subnet" {
  count                   = length(data.aws_availability_zones.available.names)
  vpc_id                  = aws_vpc.core.id
  cidr_block              = length(var.public_subnet_cidrs) > 0 ? var.public_subnet_cidrs[count.index] : cidrsubnet(var.vpc_cidr_range, var.public_subnet_size, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.public_subnet_prefix}_${replace(
      data.aws_availability_zones.available.names[count.index],
      "-",
      "_",
    )}"
    Resource = var.resource_tag
    Scope    = "public"
  }
}

# Private subnets
resource "aws_subnet" "private_subnet" {
  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.core.id
  cidr_block        = length(var.private_subnet_cidrs) > 0 ? var.private_subnet_cidrs[count.index] : cidrsubnet(var.vpc_cidr_range, var.private_subnet_size, var.private_subnet_offset + count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${local.private_subnet_prefix}_${replace(
      data.aws_availability_zones.available.names[count.index],
      "-",
      "_",
    )}"
    Resource = var.resource_tag
    Scope    = "private"
  }
}

# IGW - Internet Gateway
resource "aws_internet_gateway" "core_igw" {
  vpc_id = aws_vpc.core.id

  tags = {
    Name     = "${var.vpc_name}_igw"
    Resource = var.resource_tag
  }
}

# EIPs for NAT Gateways
resource "aws_eip" "core_nat_gw_eip" {
  count = length(data.aws_availability_zones.available.names)
  vpc   = true

  depends_on = ["aws_internet_gateway.core_igw"]

  tags = {
    Name = "${var.vpc_name}_nat_gw_eip_${replace(
      data.aws_availability_zones.available.names[count.index],
      "-",
      "_",
    )}"
    Resource = var.resource_tag
  }
}

# NAT Gateways for private subnets
resource "aws_nat_gateway" "core_nat_gw" {
  count         = length(data.aws_availability_zones.available.names)
  subnet_id     = aws_subnet.public_subnet[count.index].id
  allocation_id = aws_eip.core_nat_gw_eip[count.index].id

  tags = {
    Name = "${var.vpc_name}_nat_gw_${replace(
      data.aws_availability_zones.available.names[count.index],
      "-",
      "_",
    )}"
    Resource = var.resource_tag
  }
}

# Route tables for public/private subnets
resource "aws_route_table" "core_main_route_table" {
  vpc_id = aws_vpc.core.id

  tags = {
    Name     = "${var.vpc_name}_main_route_table_name"
    Resource = var.resource_tag
  }
}

resource "aws_route_table" "core_private_route_table" {
  count  = length(data.aws_availability_zones.available.names)
  vpc_id = aws_vpc.core.id

  tags = {
    Name = "${var.vpc_name}_private_route_table_${replace(
      data.aws_availability_zones.available.names[count.index],
      "-",
      "_",
    )}"
    Resource = var.resource_tag
  }
}

# Default public route through the IGW
resource "aws_route" "core_main_route_table_public_default_route" {
  route_table_id         = aws_route_table.core_main_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.core_igw.id
}

# Default private route through the NAT gateways
resource "aws_route" "core_private_route_table_default_route" {
  count                  = length(data.aws_availability_zones.available.names)
  route_table_id         = aws_route_table.core_private_route_table[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.core_nat_gw[count.index].id
}

# Route table associations
resource "aws_main_route_table_association" "core_main_route_table_association" {
  vpc_id         = aws_vpc.core.id
  route_table_id = aws_route_table.core_main_route_table.id
}

resource "aws_route_table_association" "core_private_route_table_association" {
  count          = length(data.aws_availability_zones.available.names)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.core_private_route_table[count.index].id
}
