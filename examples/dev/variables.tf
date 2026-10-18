variable "region" {
  type        = string
  description = "AWS region to deploy into."
  default     = "eu-west-2"

  validation {
    condition     = can(regex("^[a-z]{2}(-[a-z]+)+-\\d$", var.region))
    error_message = "region must look like an AWS region code, e.g. eu-west-2."
  }
}

variable "project" {
  type        = string
  description = "Project name, used in the resource name prefix and tags."
  default     = "vpcfoundation"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.project))
    error_message = "project must be 2-21 lowercase letters, digits or hyphens, starting with a letter."
  }
}

variable "environment" {
  type        = string
  description = "Environment name, used in the resource name prefix and tags."
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be dev, staging or prod."
  }
}

variable "cidr_block" {
  type        = string
  description = "VPC CIDR block."
  default     = "10.0.0.0/16"
}
