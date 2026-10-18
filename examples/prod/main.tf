# Prod: three AZs with a NAT gateway and route table per AZ, so losing one AZ
# never breaks egress for workloads in the other two.
module "vpc" {
  source = "../../modules/vpc"

  name             = "${var.project}-${var.environment}"
  cidr_block       = var.cidr_block
  az_count         = 3
  nat_gateway_mode = "one_per_az"

  enable_flow_logs                   = true
  flow_logs_retention_days           = 365
  flow_logs_max_aggregation_interval = 60

  enable_gateway_endpoints = true

  # Interface endpoints let SSM Session Manager, ECR pulls and log shipping work without NAT,
  # cutting NAT data-processing charges and keeping AWS API traffic on the AWS network.
  interface_endpoints = ["ssm", "ssmmessages", "ec2messages", "ecr.api", "ecr.dkr", "logs"]

  # Ready for an EKS cluster to discover subnets for public and internal load balancers.
  enable_kubernetes_tags  = true
  kubernetes_cluster_name = "${var.project}-${var.environment}"

  tags = {
    CostCentre  = "production"
    DataClass   = "confidential"
    Criticality = "high"
  }
}
