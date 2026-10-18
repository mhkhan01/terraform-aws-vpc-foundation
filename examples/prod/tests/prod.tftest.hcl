# Plan-only tests for the prod example. Offline: the AWS provider is mocked.

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

run "prod_three_azs_with_expected_cidrs" {
  command = plan

  assert {
    condition     = tolist(output.azs) == tolist(["eu-west-2a", "eu-west-2b", "eu-west-2c"])
    error_message = "Prod should span all three London AZs."
  }

  assert {
    condition = (
      output.subnet_cidrs.public == ["10.20.0.0/24", "10.20.1.0/24", "10.20.2.0/24"] &&
      output.subnet_cidrs.private == ["10.20.10.0/24", "10.20.11.0/24", "10.20.12.0/24"] &&
      output.subnet_cidrs.isolated == ["10.20.20.0/24", "10.20.21.0/24", "10.20.22.0/24"]
    )
    error_message = "Unexpected prod subnet plan: ${jsonencode(output.subnet_cidrs)}."
  }
}

run "prod_one_nat_and_route_table_per_az" {
  command = plan

  assert {
    condition     = output.nat_gateway_count == 3
    error_message = "Prod uses one_per_az and should create three NAT gateways."
  }

  assert {
    condition     = length(output.private_route_table_ids) == 3
    error_message = "Prod should have one private route table per AZ."
  }
}

run "prod_interface_endpoints_enabled" {
  command = plan

  assert {
    condition     = toset(keys(output.interface_endpoint_ids)) == toset(["ssm", "ssmmessages", "ec2messages", "ecr.api", "ecr.dkr", "logs"])
    error_message = "Prod should create the six SSM/ECR/Logs interface endpoints."
  }
}

run "prod_names_follow_convention" {
  command = plan

  assert {
    condition     = output.flow_log_group_name == "/aws/vpc-flow-logs/vpcfoundation-prod" && output.db_subnet_group_name == "vpcfoundation-prod-db"
    error_message = "Prod resource names should use the vpcfoundation-prod prefix."
  }
}

run "prod_rejects_unknown_environment" {
  command = plan

  variables {
    environment = "production"
  }

  expect_failures = [var.environment]
}
