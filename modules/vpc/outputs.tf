output "vpc_id" {
  description = "ID of the VPC."
  value       = aws_vpc.this.id
}

output "vpc_cidr_block" {
  description = "IPv4 CIDR block of the VPC."
  value       = aws_vpc.this.cidr_block
}

output "azs" {
  description = "Availability Zones the subnets were placed in, in index order."
  value       = local.azs
}

output "subnet_cidrs" {
  description = "Computed subnet CIDRs per tier (public, private, isolated), indexed by AZ."
  value       = local.subnet_cidrs
}

output "public_subnet_ids" {
  description = "IDs of the public subnets."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private (application) subnets."
  value       = aws_subnet.private[*].id
}

output "isolated_subnet_ids" {
  description = "IDs of the isolated (database) subnets. These have no route to the internet."
  value       = aws_subnet.isolated[*].id
}

output "public_route_table_id" {
  description = "ID of the shared public route table."
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs of the private route tables (one per AZ in one_per_az mode, otherwise one)."
  value       = aws_route_table.private[*].id
}

output "isolated_route_table_id" {
  description = "ID of the isolated route table."
  value       = aws_route_table.isolated.id
}

output "internet_gateway_id" {
  description = "ID of the internet gateway."
  value       = aws_internet_gateway.this.id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT gateways (empty when nat_gateway_mode = none)."
  value       = aws_nat_gateway.this[*].id
}

output "nat_gateway_count" {
  description = "Number of NAT gateways created by the selected nat_gateway_mode."
  value       = local.nat_gateway_count
}

output "nat_public_ips" {
  description = "Elastic IPs attached to the NAT gateways - allowlist these with third parties."
  value       = aws_eip.nat[*].public_ip
}

output "db_subnet_group_name" {
  description = "Name of the RDS DB subnet group, or null if not created."
  value       = try(aws_db_subnet_group.this[0].name, null)
}

output "gateway_endpoint_ids" {
  description = "Map of gateway endpoint service name to endpoint ID."
  value       = { for k, v in aws_vpc_endpoint.gateway : k => v.id }
}

output "interface_endpoint_ids" {
  description = "Map of interface endpoint service name to endpoint ID."
  value       = { for k, v in aws_vpc_endpoint.interface : k => v.id }
}

output "interface_endpoint_security_group_id" {
  description = "Security group attached to interface endpoints, or null if none were requested."
  value       = try(aws_security_group.endpoints[0].id, null)
}

output "flow_log_id" {
  description = "ID of the VPC flow log, or null if disabled."
  value       = try(aws_flow_log.this[0].id, null)
}

output "flow_log_group_name" {
  description = "CloudWatch Logs group receiving flow logs, or null if disabled."
  value       = try(aws_cloudwatch_log_group.flow_logs[0].name, null)
}

output "flow_log_kms_key_arn" {
  description = "ARN of the KMS key encrypting the flow log group, or null if disabled."
  value       = try(aws_kms_key.flow_logs[0].arn, null)
}
