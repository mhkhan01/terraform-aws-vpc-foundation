# Dev: two AZs and a single shared NAT gateway. Roughly a third of the prod NAT bill,
# accepting that an AZ outage in the NAT's AZ cuts private-subnet egress.
module "vpc" {
  source = "../../modules/vpc"

  name             = "${var.project}-${var.environment}"
  cidr_block       = var.cidr_block
  az_count         = 2
  nat_gateway_mode = "single"

  # Flow logs stay on (cheap at dev volumes) but with short retention to limit storage cost.
  enable_flow_logs         = true
  flow_logs_retention_days = 30

  # Gateway endpoints are free; interface endpoints are skipped in dev to save ~USD 15/month each.
  enable_gateway_endpoints = true
  interface_endpoints      = []

  tags = {
    CostCentre = "dev-sandbox"
  }
}
