################################################################################
# Gateway endpoints (free) - S3 and DynamoDB
################################################################################

resource "aws_vpc_endpoint" "gateway" {
  for_each = var.enable_gateway_endpoints ? toset(["s3", "dynamodb"]) : toset([])

  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.${each.key}"
  vpc_endpoint_type = "Gateway"

  # Isolated subnets get these too: databases can reach S3 backups without any internet path.
  route_table_ids = concat(aws_route_table.private[*].id, [aws_route_table.isolated.id])

  tags = merge(local.tags, { Name = "${local.name}-${each.key}-gateway" })
}

################################################################################
# Interface endpoints (optional, billed per AZ-hour)
################################################################################

resource "aws_security_group" "endpoints" {
  count = length(var.interface_endpoints) > 0 ? 1 : 0

  name        = "${local.name}-vpc-endpoints"
  description = "HTTPS from inside the VPC to interface endpoints"
  vpc_id      = aws_vpc.this.id

  tags = merge(local.tags, { Name = "${local.name}-vpc-endpoints" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "endpoints_https" {
  count = length(var.interface_endpoints) > 0 ? 1 : 0

  security_group_id = aws_security_group.endpoints[0].id
  description       = "HTTPS from VPC CIDR"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = aws_vpc.this.cidr_block

  tags = merge(local.tags, { Name = "${local.name}-vpc-endpoints-https" })
}

resource "aws_vpc_endpoint" "interface" {
  for_each = toset(var.interface_endpoints)

  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.${each.key}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.endpoints[0].id]
  private_dns_enabled = true

  tags = merge(local.tags, { Name = "${local.name}-${replace(each.key, ".", "-")}" })
}
