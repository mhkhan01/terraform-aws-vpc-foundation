data "aws_availability_zones" "available" {
  state = "available"

  # Local Zones and Wavelength Zones have limited service support; keep to standard AZs.
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  name = var.name

  azs = length(var.azs) > 0 ? var.azs : slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Subnet plan is derived purely from inputs so it is known at plan time and testable offline.
  # netnum = tier offset + AZ index; e.g. 10.0.0.0/16 with newbits 8 -> public 10.0.0.0/24, private 10.0.10.0/24, isolated 10.0.20.0/24.
  tiers = ["public", "private", "isolated"]

  subnet_cidrs = {
    for tier in local.tiers : tier => [
      for i in range(var.az_count) : cidrsubnet(var.cidr_block, var.subnet_newbits, var.subnet_netnum_offsets[tier] + i)
    ]
  }

  nat_gateway_count = {
    none       = 0
    single     = 1
    one_per_az = var.az_count
  }[var.nat_gateway_mode]

  # One private route table per AZ only when each AZ has its own NAT; otherwise a shared table avoids needless resources.
  private_route_table_count = var.nat_gateway_mode == "one_per_az" ? var.az_count : 1

  k8s_cluster_tag = var.enable_kubernetes_tags && var.kubernetes_cluster_name != "" ? {
    "kubernetes.io/cluster/${var.kubernetes_cluster_name}" = "shared"
  } : {}

  public_k8s_tags  = var.enable_kubernetes_tags ? merge({ "kubernetes.io/role/elb" = "1" }, local.k8s_cluster_tag) : {}
  private_k8s_tags = var.enable_kubernetes_tags ? merge({ "kubernetes.io/role/internal-elb" = "1" }, local.k8s_cluster_tag) : {}

  flow_log_group_name = "/aws/vpc-flow-logs/${local.name}"

  tags = merge(var.tags, { Module = "terraform-aws-vpc-foundation" })
}
