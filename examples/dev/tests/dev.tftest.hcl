# Plan-only tests for the dev example. Offline: the AWS provider is mocked.

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

run "dev_cidr_math_10_0_0_0_16" {
  command = plan

  assert {
    condition     = output.subnet_cidrs.public == ["10.0.0.0/24", "10.0.1.0/24"]
    error_message = "Public subnets should be 10.0.0.0/24 and 10.0.1.0/24, got ${jsonencode(output.subnet_cidrs.public)}."
  }

  assert {
    condition     = output.subnet_cidrs.private == ["10.0.10.0/24", "10.0.11.0/24"]
    error_message = "Private subnets should be 10.0.10.0/24 and 10.0.11.0/24, got ${jsonencode(output.subnet_cidrs.private)}."
  }

  assert {
    condition     = output.subnet_cidrs.isolated == ["10.0.20.0/24", "10.0.21.0/24"]
    error_message = "Isolated subnets should be 10.0.20.0/24 and 10.0.21.0/24, got ${jsonencode(output.subnet_cidrs.isolated)}."
  }

  assert {
    condition     = tolist(output.azs) == tolist(["eu-west-2a", "eu-west-2b"])
    error_message = "Dev should use the first two AZs."
  }
}

run "dev_single_nat_and_shared_private_route_table" {
  command = plan

  assert {
    condition     = output.nat_gateway_count == 1
    error_message = "Dev uses nat_gateway_mode = single and should create exactly one NAT gateway."
  }

  assert {
    condition     = length(output.private_route_table_ids) == 1
    error_message = "Single NAT mode should share one private route table across AZs."
  }

  assert {
    condition     = length(output.interface_endpoint_ids) == 0
    error_message = "Dev should not create any (billable) interface endpoints."
  }
}

run "dev_flow_logs_and_db_subnet_group_named" {
  command = plan

  assert {
    condition     = output.flow_log_group_name == "/aws/vpc-flow-logs/vpcfoundation-dev"
    error_message = "Flow log group should follow the /aws/vpc-flow-logs/<name> convention."
  }

  assert {
    condition     = output.db_subnet_group_name == "vpcfoundation-dev-db"
    error_message = "DB subnet group should be named <name>-db."
  }
}

run "dev_custom_cidr_shifts_every_subnet" {
  command = plan

  variables {
    cidr_block = "172.16.0.0/20"
  }

  # /20 + 8 newbits = /28; the tier offsets still apply.
  assert {
    condition     = output.subnet_cidrs.public[0] == "172.16.0.0/28" && output.subnet_cidrs.private[1] == "172.16.0.176/28" && output.subnet_cidrs.isolated[0] == "172.16.1.64/28"
    error_message = "Subnet CIDRs should be derived from the VPC CIDR, got ${jsonencode(output.subnet_cidrs)}."
  }
}
