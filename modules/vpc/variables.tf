variable "name" {
  type        = string
  description = "Name prefix applied to every resource (e.g. \"acme-dev\"). Lowercase letters, digits and hyphens only."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,30}[a-z0-9]$", var.name))
    error_message = "name must be 3-32 characters, start with a letter, and contain only lowercase letters, digits and hyphens."
  }
}

variable "cidr_block" {
  type        = string
  description = "IPv4 CIDR block for the VPC. Must be a valid network address with a prefix between /16 and /24."
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.cidr_block, 0)) && can(regex("^\\d+\\.\\d+\\.\\d+\\.\\d+/\\d+$", var.cidr_block))
    error_message = "cidr_block must be a valid IPv4 CIDR, e.g. 10.0.0.0/16."
  }

  validation {
    # Reject host addresses such as 10.0.0.5/16 - AWS would silently realign them and the computed subnet plan would no longer match.
    condition     = can(cidrhost(var.cidr_block, 0)) && try(cidrhost(var.cidr_block, 0) == split("/", var.cidr_block)[0], false)
    error_message = "cidr_block must be a network address (host bits zero), e.g. 10.0.0.0/16 not 10.0.0.5/16."
  }

  validation {
    condition     = can(cidrhost(var.cidr_block, 0)) && try(tonumber(split("/", var.cidr_block)[1]) >= 16 && tonumber(split("/", var.cidr_block)[1]) <= 24, false)
    error_message = "cidr_block prefix length must be between /16 and /24 (AWS VPC limits are /16 to /28; /24 leaves room for three tiers)."
  }
}

variable "az_count" {
  type        = number
  description = "Number of Availability Zones to spread subnets across. 2 for cost-sensitive environments, 3 for production."
  default     = 2

  validation {
    condition     = var.az_count >= 2 && var.az_count <= 3 && floor(var.az_count) == var.az_count
    error_message = "az_count must be 2 or 3."
  }
}

variable "azs" {
  type        = list(string)
  description = "Optional explicit list of AZ names. Leave empty to use the first az_count available AZs in the region."
  default     = []

  validation {
    condition     = length(var.azs) == 0 || length(var.azs) == var.az_count
    error_message = "azs must be empty or contain exactly az_count entries."
  }
}

variable "subnet_newbits" {
  type        = number
  description = "Bits added to the VPC prefix for each subnet (cidrsubnet newbits). 8 on a /16 gives /24 subnets (251 usable IPs each)."
  default     = 8

  validation {
    condition     = var.subnet_newbits >= 2 && var.subnet_newbits <= 12 && floor(var.subnet_newbits) == var.subnet_newbits
    error_message = "subnet_newbits must be a whole number between 2 and 12."
  }

  validation {
    condition     = !can(cidrhost(var.cidr_block, 0)) || try(tonumber(split("/", var.cidr_block)[1]) + var.subnet_newbits <= 28, true)
    error_message = "cidr_block prefix + subnet_newbits must not exceed 28 (AWS minimum subnet size is /28)."
  }
}

variable "subnet_netnum_offsets" {
  type = object({
    public   = number
    private  = number
    isolated = number
  })
  description = "Starting cidrsubnet netnum for each tier. AZ index is added to the offset, so offsets must be at least 3 apart to leave room for a third AZ."
  default = {
    public   = 0
    private  = 10
    isolated = 20
  }

  validation {
    condition = (
      abs(var.subnet_netnum_offsets.public - var.subnet_netnum_offsets.private) >= 3 &&
      abs(var.subnet_netnum_offsets.public - var.subnet_netnum_offsets.isolated) >= 3 &&
      abs(var.subnet_netnum_offsets.private - var.subnet_netnum_offsets.isolated) >= 3 &&
      min(var.subnet_netnum_offsets.public, var.subnet_netnum_offsets.private, var.subnet_netnum_offsets.isolated) >= 0
    )
    error_message = "subnet_netnum_offsets must be non-negative and at least 3 apart so tiers never overlap."
  }

  validation {
    condition = max(
      var.subnet_netnum_offsets.public,
      var.subnet_netnum_offsets.private,
      var.subnet_netnum_offsets.isolated
    ) + 3 <= pow(2, var.subnet_newbits)
    error_message = "The highest netnum offset plus 3 AZs must fit within 2^subnet_newbits subnets."
  }
}

variable "nat_gateway_mode" {
  type        = string
  description = "NAT strategy for the private tier: \"none\" (no outbound internet, cheapest), \"single\" (one shared NAT, cheap but one AZ is a single point of failure), \"one_per_az\" (HA, one NAT and route table per AZ)."
  default     = "single"

  validation {
    condition     = contains(["none", "single", "one_per_az"], var.nat_gateway_mode)
    error_message = "nat_gateway_mode must be one of: none, single, one_per_az."
  }
}

variable "map_public_ip_on_launch" {
  type        = bool
  description = "Auto-assign public IPs in public subnets. Off by default: load balancers and NAT do not need it, and it prevents accidental exposure of instances."
  default     = false
}

variable "enable_flow_logs" {
  type        = bool
  description = "Send VPC Flow Logs to a KMS-encrypted CloudWatch Logs group. Costs ingestion + storage; disable only for throwaway sandboxes."
  default     = true
}

variable "flow_logs_retention_days" {
  type        = number
  description = "Retention for the flow log group, in days. 365 meets common audit baselines; lower it in dev to save storage cost."
  default     = 365

  validation {
    condition     = contains([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], var.flow_logs_retention_days)
    error_message = "flow_logs_retention_days must be a value CloudWatch Logs accepts (e.g. 7, 30, 90, 365)."
  }
}

variable "flow_logs_traffic_type" {
  type        = string
  description = "Traffic captured by flow logs: ACCEPT, REJECT or ALL."
  default     = "ALL"

  validation {
    condition     = contains(["ACCEPT", "REJECT", "ALL"], var.flow_logs_traffic_type)
    error_message = "flow_logs_traffic_type must be ACCEPT, REJECT or ALL."
  }
}

variable "flow_logs_max_aggregation_interval" {
  type        = number
  description = "Flow log aggregation window in seconds: 60 (faster troubleshooting) or 600 (fewer records, cheaper)."
  default     = 600

  validation {
    condition     = contains([60, 600], var.flow_logs_max_aggregation_interval)
    error_message = "flow_logs_max_aggregation_interval must be 60 or 600."
  }
}

variable "enable_gateway_endpoints" {
  type        = bool
  description = "Create S3 and DynamoDB gateway endpoints on private and isolated route tables. Free, and keeps that traffic off NAT (which is billed per GB)."
  default     = true
}

variable "interface_endpoints" {
  type        = list(string)
  description = "AWS service short names to create interface endpoints for, e.g. [\"ssm\", \"ssmmessages\", \"ec2messages\", \"ecr.api\", \"ecr.dkr\", \"logs\"]. Each costs roughly USD 7-8/month per AZ."
  default     = []

  validation {
    condition     = alltrue([for s in var.interface_endpoints : can(regex("^[a-z0-9][a-z0-9.-]*[a-z0-9]$", s))])
    error_message = "interface_endpoints entries must be service short names such as \"ssm\" or \"ecr.dkr\"."
  }

  validation {
    condition     = length(var.interface_endpoints) == length(distinct(var.interface_endpoints))
    error_message = "interface_endpoints must not contain duplicates."
  }
}

variable "enable_kubernetes_tags" {
  type        = bool
  description = "Tag public subnets with kubernetes.io/role/elb and private subnets with kubernetes.io/role/internal-elb so EKS / the AWS Load Balancer Controller can discover them."
  default     = false
}

variable "kubernetes_cluster_name" {
  type        = string
  description = "Optional EKS cluster name. When set with enable_kubernetes_tags, adds kubernetes.io/cluster/<name> = shared to public and private subnets."
  default     = ""
}

variable "create_db_subnet_group" {
  type        = bool
  description = "Create an RDS DB subnet group spanning the isolated subnets."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Additional tags merged onto every resource."
  default     = {}
}
