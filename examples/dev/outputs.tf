output "vpc_id" {
  description = "ID of the dev VPC."
  value       = module.vpc.vpc_id
}

output "azs" {
  description = "AZs used by the dev VPC."
  value       = module.vpc.azs
}

output "subnet_cidrs" {
  description = "Computed subnet CIDRs per tier."
  value       = module.vpc.subnet_cidrs
}

output "public_subnet_ids" {
  description = "Public subnet IDs."
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs."
  value       = module.vpc.private_subnet_ids
}

output "isolated_subnet_ids" {
  description = "Isolated subnet IDs."
  value       = module.vpc.isolated_subnet_ids
}

output "nat_gateway_count" {
  description = "Number of NAT gateways."
  value       = module.vpc.nat_gateway_count
}

output "private_route_table_ids" {
  description = "Private route table IDs."
  value       = module.vpc.private_route_table_ids
}

output "db_subnet_group_name" {
  description = "RDS DB subnet group name."
  value       = module.vpc.db_subnet_group_name
}

output "interface_endpoint_ids" {
  description = "Interface endpoint IDs by service."
  value       = module.vpc.interface_endpoint_ids
}

output "flow_log_group_name" {
  description = "Flow log CloudWatch Logs group."
  value       = module.vpc.flow_log_group_name
}
