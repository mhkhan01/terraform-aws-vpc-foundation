################################################################################
# VPC
################################################################################

resource "aws_vpc" "this" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true # required for interface endpoint private DNS

  tags = merge(local.tags, { Name = local.name })
}

# Lock down the default security group: anything launched without an explicit SG gets no access.
resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  # Explicit empty lists make Terraform strip any rules AWS or a console user adds.
  ingress = []
  egress  = []

  tags = merge(local.tags, { Name = "${local.name}-default-locked" })
}

# Bring the default NACL under management so console edits are detected as drift.
# Security groups remain the primary control; NACLs stay permissive to avoid breaking ephemeral return traffic.
resource "aws_default_network_acl" "this" {
  default_network_acl_id = aws_vpc.this.default_network_acl_id

  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(local.tags, { Name = "${local.name}-default" })

  lifecycle {
    # Subnets attach to the default NACL implicitly; tracking them here would cause perpetual diffs.
    ignore_changes = [subnet_ids]
  }
}

################################################################################
# Subnets
################################################################################

resource "aws_subnet" "public" {
  count = var.az_count

  vpc_id                  = aws_vpc.this.id
  cidr_block              = local.subnet_cidrs.public[count.index]
  availability_zone       = local.azs[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(local.tags, local.public_k8s_tags, {
    Name = "${local.name}-public-${local.azs[count.index]}"
    Tier = "public"
  })
}

resource "aws_subnet" "private" {
  count = var.az_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.subnet_cidrs.private[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(local.tags, local.private_k8s_tags, {
    Name = "${local.name}-private-${local.azs[count.index]}"
    Tier = "private"
  })
}

resource "aws_subnet" "isolated" {
  count = var.az_count

  vpc_id            = aws_vpc.this.id
  cidr_block        = local.subnet_cidrs.isolated[count.index]
  availability_zone = local.azs[count.index]

  tags = merge(local.tags, {
    Name = "${local.name}-isolated-${local.azs[count.index]}"
    Tier = "isolated"
  })
}

################################################################################
# Internet gateway + public routing
################################################################################

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.tags, { Name = "${local.name}-igw" })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.tags, { Name = "${local.name}-public", Tier = "public" })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  count = var.az_count

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

################################################################################
# NAT gateways + private routing
################################################################################

resource "aws_eip" "nat" {
  count = local.nat_gateway_count

  domain = "vpc"

  tags = merge(local.tags, { Name = "${local.name}-nat-${local.azs[count.index]}" })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_nat_gateway" "this" {
  count = local.nat_gateway_count

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(local.tags, { Name = "${local.name}-nat-${local.azs[count.index]}" })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "private" {
  count = local.private_route_table_count

  vpc_id = aws_vpc.this.id

  tags = merge(local.tags, {
    Name = local.private_route_table_count > 1 ? "${local.name}-private-${local.azs[count.index]}" : "${local.name}-private"
    Tier = "private"
  })
}

# In one_per_az mode route table N uses NAT N, so losing one AZ does not take down egress for the others.
resource "aws_route" "private_nat" {
  count = local.nat_gateway_count > 0 ? local.private_route_table_count : 0

  route_table_id         = aws_route_table.private[count.index].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.this[min(count.index, local.nat_gateway_count - 1)].id
}

resource "aws_route_table_association" "private" {
  count = var.az_count

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[local.private_route_table_count > 1 ? count.index : 0].id
}

################################################################################
# Isolated routing - local routes + gateway endpoints only, never a default route
################################################################################

resource "aws_route_table" "isolated" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.tags, { Name = "${local.name}-isolated", Tier = "isolated" })
}

resource "aws_route_table_association" "isolated" {
  count = var.az_count

  subnet_id      = aws_subnet.isolated[count.index].id
  route_table_id = aws_route_table.isolated.id
}

resource "aws_db_subnet_group" "this" {
  count = var.create_db_subnet_group ? 1 : 0

  name        = "${local.name}-db"
  description = "Isolated subnets for ${local.name} databases"
  subnet_ids  = aws_subnet.isolated[*].id

  tags = merge(local.tags, { Name = "${local.name}-db" })
}
