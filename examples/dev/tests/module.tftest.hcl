# Plan-only tests that drive modules/vpc directly so internal resources can be asserted.
# Offline: the AWS provider is mocked.
mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = {
      names = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_data "aws_region" {
    defaults = {
      region = "eu-west-2"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{}"
    }
  }
}

# Deterministic IDs, known at plan time, so assertions can prove which route table,
# NAT gateway and subnet each resource is wired to.
override_resource {
  target          = aws_route_table.public
  override_during = plan
  values          = { id = "rtb-public" }
}

override_resource {
  target          = aws_route_table.isolated
  override_during = plan
  values          = { id = "rtb-isolated" }
}

override_resource {
  target          = aws_kms_key.flow_logs[0]
  override_during = plan
  values          = { arn = "arn:aws:kms:eu-west-2:123456789012:key/flow-logs" }
}

override_resource {
  target          = aws_route_table.private[0]
  override_during = plan
  values          = { id = "rtb-private-0" }
}

override_resource {
  target          = aws_nat_gateway.this[0]
  override_during = plan
  values          = { id = "nat-0" }
}

override_resource {
  target          = aws_subnet.public[0]
  override_during = plan
  values          = { id = "subnet-public-0" }
}

override_resource {
  target          = aws_subnet.isolated[0]
  override_during = plan
  values          = { id = "subnet-isolated-0" }
}

override_resource {
  target          = aws_route_table.private[1]
  override_during = plan
  values          = { id = "rtb-private-1" }
}

override_resource {
  target          = aws_nat_gateway.this[1]
  override_during = plan
  values          = { id = "nat-1" }
}

override_resource {
  target          = aws_subnet.public[1]
  override_during = plan
  values          = { id = "subnet-public-1" }
}

override_resource {
  target          = aws_subnet.isolated[1]
  override_during = plan
  values          = { id = "subnet-isolated-1" }
}

override_resource {
  target          = aws_route_table.private[2]
  override_during = plan
  values          = { id = "rtb-private-2" }
}

override_resource {
  target          = aws_nat_gateway.this[2]
  override_during = plan
  values          = { id = "nat-2" }
}

override_resource {
  target          = aws_subnet.public[2]
  override_during = plan
  values          = { id = "subnet-public-2" }
}

override_resource {
  target          = aws_subnet.isolated[2]
  override_during = plan
  values          = { id = "subnet-isolated-2" }
}

variables {
  name       = "unit"
  cidr_block = "10.0.0.0/16"
}

run "nat_mode_none_creates_no_nat_or_default_route" {
  command = plan

  module {
    source = "../../modules/vpc"
  }

  variables {
    nat_gateway_mode = "none"
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 0 && length(aws_eip.nat) == 0
    error_message = "nat_gateway_mode = none must create no NAT gateways or EIPs."
  }

  assert {
    condition     = length(aws_route.private_nat) == 0
    error_message = "Without NAT the private tier must have no default route."
  }

  assert {
    condition     = length(aws_route_table.private) == 1
    error_message = "nat_gateway_mode = none should use one shared private route table."
  }
}

run "nat_mode_single_shares_one_nat" {
  command = plan

  module {
    source = "../../modules/vpc"
  }

  variables {
    az_count         = 3
    nat_gateway_mode = "single"
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 1 && length(aws_eip.nat) == 1
    error_message = "nat_gateway_mode = single must create exactly one NAT gateway and EIP."
  }

  assert {
    condition     = length(aws_route_table.private) == 1 && length(aws_route.private_nat) == 1
    error_message = "Single NAT mode should have one private route table with one NAT route."
  }

  assert {
    condition     = alltrue([for a in aws_route_table_association.private : a.route_table_id == aws_route_table.private[0].id])
    error_message = "All private subnets should share the single private route table."
  }
}

run "nat_mode_one_per_az_is_ha" {
  command = plan

  module {
    source = "../../modules/vpc"
  }

  variables {
    az_count         = 3
    nat_gateway_mode = "one_per_az"
  }

  assert {
    condition     = length(aws_nat_gateway.this) == 3 && length(aws_eip.nat) == 3
    error_message = "one_per_az with 3 AZs must create three NAT gateways and EIPs."
  }

  assert {
    condition     = length(aws_route_table.private) == 3 && length(aws_route.private_nat) == 3
    error_message = "one_per_az must create a private route table and NAT route per AZ."
  }

  assert {
    condition     = alltrue([for i in range(3) : aws_route.private_nat[i].nat_gateway_id == aws_nat_gateway.this[i].id])
    error_message = "Each AZ's private route table must point at the NAT gateway in the same AZ."
  }

  assert {
    condition     = alltrue([for i in range(3) : aws_nat_gateway.this[i].subnet_id == aws_subnet.public[i].id])
    error_message = "Each NAT gateway must sit in the public subnet of its own AZ."
  }
}

run "isolated_tier_has_no_internet_route" {
  command = plan

  module {
    source = "../../modules/vpc"
  }

  variables {
    az_count         = 3
    nat_gateway_mode = "one_per_az"
  }

  # Every 0.0.0.0/0 route in the module, whether to IGW or NAT, must target a non-isolated table.
  assert {
    condition = alltrue([
      for r in concat(aws_route.private_nat, [aws_route.public_internet]) :
      r.route_table_id != aws_route_table.isolated.id
    ])
    error_message = "No default route may be attached to the isolated route table."
  }

  assert {
    condition     = alltrue([for a in aws_route_table_association.isolated : a.route_table_id == aws_route_table.isolated.id])
    error_message = "Isolated subnets must only associate with the isolated route table."
  }

  assert {
    condition     = alltrue([for e in aws_vpc_endpoint.gateway : contains(e.route_table_ids, aws_route_table.isolated.id)])
    error_message = "S3 and DynamoDB gateway endpoints must be attached to the isolated route table."
  }

  assert {
    condition     = toset(aws_db_subnet_group.this[0].subnet_ids) == toset(aws_subnet.isolated[*].id)
    error_message = "The DB subnet group must use the isolated subnets only."
  }
}

run "three_az_cidr_math" {
  command = plan

  module {
    source = "../../modules/vpc"
  }

  variables {
    az_count = 3
  }

  assert {
    condition = (
      aws_subnet.public[2].cidr_block == "10.0.2.0/24" &&
      aws_subnet.private[2].cidr_block == "10.0.12.0/24" &&
      aws_subnet.isolated[2].cidr_block == "10.0.22.0/24"
    )
    error_message = "Third-AZ subnets should be 10.0.2.0/24, 10.0.12.0/24 and 10.0.22.0/24."
  }

  assert {
    condition     = [for s in aws_subnet.private : s.availability_zone] == ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
    error_message = "Subnets should be spread one per AZ in order."
  }
}

run "custom_newbits_produce_larger_subnets" {
  command = plan

  module {
    source = "../../modules/vpc"
  }

  variables {
    subnet_newbits = 4
    subnet_netnum_offsets = {
      public   = 0
      private  = 4
      isolated = 8
    }
  }

  assert {
    condition     = aws_subnet.public[0].cidr_block == "10.0.0.0/20" && aws_subnet.private[0].cidr_block == "10.0.64.0/20" && aws_subnet.isolated[1].cidr_block == "10.0.144.0/20"
    error_message = "newbits = 4 on a /16 should yield /20 subnets at the configured offsets."
  }
}

run "interface_endpoints_and_sg" {
  command = plan

  module {
    source = "../../modules/vpc"
  }

  variables {
    interface_endpoints = ["ssm", "ssmmessages", "ec2messages", "ecr.api", "ecr.dkr", "logs"]
  }

  assert {
    condition     = length(aws_vpc_endpoint.interface) == 6
    error_message = "One interface endpoint per requested service expected."
  }

  assert {
    condition     = aws_vpc_endpoint.interface["ecr.dkr"].service_name == "com.amazonaws.eu-west-2.ecr.dkr" && aws_vpc_endpoint.interface["ssm"].private_dns_enabled
    error_message = "Interface endpoint service names must be regional and use private DNS."
  }

  assert {
    condition = (
      aws_vpc_security_group_ingress_rule.endpoints_https[0].from_port == 443 &&
      aws_vpc_security_group_ingress_rule.endpoints_https[0].to_port == 443 &&
      aws_vpc_security_group_ingress_rule.endpoints_https[0].cidr_ipv4 == "10.0.0.0/16"
    )
    error_message = "Endpoint security group must allow only 443 from the VPC CIDR."
  }
}

run "toggles_off_remove_optional_resources" {
  command = plan

  module {
    source = "../../modules/vpc"
  }

  variables {
    enable_flow_logs         = false
    enable_gateway_endpoints = false
    create_db_subnet_group   = false
  }

  assert {
    condition = (
      length(aws_flow_log.this) == 0 &&
      length(aws_cloudwatch_log_group.flow_logs) == 0 &&
      length(aws_kms_key.flow_logs) == 0 &&
      length(aws_iam_role.flow_logs) == 0
    )
    error_message = "Disabling flow logs must remove the log group, KMS key, IAM role and flow log."
  }

  assert {
    condition     = length(aws_vpc_endpoint.gateway) == 0 && length(aws_security_group.endpoints) == 0 && length(aws_db_subnet_group.this) == 0
    error_message = "Disabled endpoints / DB subnet group must not be created."
  }
}

run "flow_logs_encrypted_with_retention" {
  command = plan

  module {
    source = "../../modules/vpc"
  }

  variables {
    flow_logs_retention_days = 90
  }

  assert {
    condition     = aws_cloudwatch_log_group.flow_logs[0].retention_in_days == 90 && aws_cloudwatch_log_group.flow_logs[0].kms_key_id == aws_kms_key.flow_logs[0].arn
    error_message = "Flow log group must be KMS-encrypted and honour the retention variable."
  }

  assert {
    condition     = aws_kms_key.flow_logs[0].enable_key_rotation
    error_message = "Flow log KMS key must have rotation enabled."
  }
}

run "kubernetes_tags" {
  command = plan

  module {
    source = "../../modules/vpc"
  }

  variables {
    enable_kubernetes_tags  = true
    kubernetes_cluster_name = "demo"
  }

  assert {
    condition     = alltrue([for s in aws_subnet.public : s.tags["kubernetes.io/role/elb"] == "1" && s.tags["kubernetes.io/cluster/demo"] == "shared"])
    error_message = "Public subnets must carry the ELB discovery tag."
  }

  assert {
    condition     = alltrue([for s in aws_subnet.private : s.tags["kubernetes.io/role/internal-elb"] == "1"])
    error_message = "Private subnets must carry the internal-ELB discovery tag."
  }

  assert {
    condition     = alltrue([for s in aws_subnet.isolated : !contains(keys(s.tags), "kubernetes.io/role/internal-elb") && !contains(keys(s.tags), "kubernetes.io/role/elb")])
    error_message = "Isolated subnets must never be offered to Kubernetes load balancers."
  }
}

run "default_security_group_is_locked_down" {
  command = plan

  module {
    source = "../../modules/vpc"
  }

  assert {
    condition     = length(aws_default_security_group.this.ingress) == 0 && length(aws_default_security_group.this.egress) == 0
    error_message = "The default security group must have no rules."
  }

  assert {
    condition     = aws_subnet.public[0].map_public_ip_on_launch == false
    error_message = "Public subnets must not auto-assign public IPs by default."
  }
}

# ---- Validation failures --------------------------------------------------

run "rejects_invalid_cidr" {
  command = plan

  module {
    source = "../../modules/vpc"
  }

  variables {
    cidr_block = "10.0.0.300/16"
  }

  expect_failures = [var.cidr_block]
}

run "rejects_host_address_cidr" {
  command = plan

  module {
    source = "../../modules/vpc"
  }

  variables {
    cidr_block = "10.0.0.5/16"
  }

  expect_failures = [var.cidr_block]
}

run "rejects_too_small_vpc" {
  command = plan

  module {
    source = "../../modules/vpc"
  }

  variables {
    cidr_block = "10.0.0.0/26"
  }

  expect_failures = [var.cidr_block]
}

run "rejects_az_count_5" {
  command = plan

  module {
    source = "../../modules/vpc"
  }

  variables {
    az_count = 5
  }

  expect_failures = [var.az_count]
}

run "rejects_unknown_nat_mode" {
  command = plan

  module {
    source = "../../modules/vpc"
  }

  variables {
    nat_gateway_mode = "two"
  }

  expect_failures = [var.nat_gateway_mode]
}

run "rejects_overlapping_tier_offsets" {
  command = plan

  module {
    source = "../../modules/vpc"
  }

  variables {
    subnet_netnum_offsets = {
      public   = 0
      private  = 1
      isolated = 20
    }
  }

  expect_failures = [var.subnet_netnum_offsets]
}
