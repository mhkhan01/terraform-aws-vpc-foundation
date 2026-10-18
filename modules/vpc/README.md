# modules/vpc

Multi-AZ VPC with public, private (application) and isolated (database) tiers. Subnet CIDRs are computed with `cidrsubnet()` from `cidr_block`, `subnet_newbits` and `subnet_netnum_offsets`; NAT topology is chosen with `nat_gateway_mode`.

```hcl
module "vpc" {
  source = "github.com/mhkhan01/terraform-aws-vpc-foundation//modules/vpc"

  name             = "acme-prod"
  cidr_block       = "10.20.0.0/16"
  az_count         = 3
  nat_gateway_mode = "one_per_az"

  interface_endpoints = ["ssm", "ssmmessages", "ec2messages", "ecr.api", "ecr.dkr", "logs"]
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.69.1 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_db_subnet_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_default_network_acl.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_network_acl) | resource |
| [aws_default_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/default_security_group) | resource |
| [aws_eip.nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_flow_log.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/flow_log) | resource |
| [aws_iam_role.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_internet_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_kms_alias.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.flow_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_nat_gateway.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/nat_gateway) | resource |
| [aws_route.private_nat](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route.public_internet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route) | resource |
| [aws_route_table.isolated](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.isolated](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_route_table_association.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.endpoints](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.isolated](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.private](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_subnet.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_endpoint.gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_endpoint.interface](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_endpoint) | resource |
| [aws_vpc_security_group_ingress_rule.endpoints_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_availability_zones.available](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/availability_zones) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.flow_logs_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.flow_logs_kms](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.flow_logs_write](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_az_count"></a> [az\_count](#input\_az\_count) | Number of Availability Zones to spread subnets across. 2 for cost-sensitive environments, 3 for production. | `number` | `2` | no |
| <a name="input_azs"></a> [azs](#input\_azs) | Optional explicit list of AZ names. Leave empty to use the first az\_count available AZs in the region. | `list(string)` | `[]` | no |
| <a name="input_cidr_block"></a> [cidr\_block](#input\_cidr\_block) | IPv4 CIDR block for the VPC. Must be a valid network address with a prefix between /16 and /24. | `string` | `"10.0.0.0/16"` | no |
| <a name="input_create_db_subnet_group"></a> [create\_db\_subnet\_group](#input\_create\_db\_subnet\_group) | Create an RDS DB subnet group spanning the isolated subnets. | `bool` | `true` | no |
| <a name="input_enable_flow_logs"></a> [enable\_flow\_logs](#input\_enable\_flow\_logs) | Send VPC Flow Logs to a KMS-encrypted CloudWatch Logs group. Costs ingestion + storage; disable only for throwaway sandboxes. | `bool` | `true` | no |
| <a name="input_enable_gateway_endpoints"></a> [enable\_gateway\_endpoints](#input\_enable\_gateway\_endpoints) | Create S3 and DynamoDB gateway endpoints on private and isolated route tables. Free, and keeps that traffic off NAT (which is billed per GB). | `bool` | `true` | no |
| <a name="input_enable_kubernetes_tags"></a> [enable\_kubernetes\_tags](#input\_enable\_kubernetes\_tags) | Tag public subnets with kubernetes.io/role/elb and private subnets with kubernetes.io/role/internal-elb so EKS / the AWS Load Balancer Controller can discover them. | `bool` | `false` | no |
| <a name="input_flow_logs_max_aggregation_interval"></a> [flow\_logs\_max\_aggregation\_interval](#input\_flow\_logs\_max\_aggregation\_interval) | Flow log aggregation window in seconds: 60 (faster troubleshooting) or 600 (fewer records, cheaper). | `number` | `600` | no |
| <a name="input_flow_logs_retention_days"></a> [flow\_logs\_retention\_days](#input\_flow\_logs\_retention\_days) | Retention for the flow log group, in days. 365 meets common audit baselines; lower it in dev to save storage cost. | `number` | `365` | no |
| <a name="input_flow_logs_traffic_type"></a> [flow\_logs\_traffic\_type](#input\_flow\_logs\_traffic\_type) | Traffic captured by flow logs: ACCEPT, REJECT or ALL. | `string` | `"ALL"` | no |
| <a name="input_interface_endpoints"></a> [interface\_endpoints](#input\_interface\_endpoints) | AWS service short names to create interface endpoints for, e.g. ["ssm", "ssmmessages", "ec2messages", "ecr.api", "ecr.dkr", "logs"]. Each costs roughly USD 7-8/month per AZ. | `list(string)` | `[]` | no |
| <a name="input_kubernetes_cluster_name"></a> [kubernetes\_cluster\_name](#input\_kubernetes\_cluster\_name) | Optional EKS cluster name. When set with enable\_kubernetes\_tags, adds kubernetes.io/cluster/<name> = shared to public and private subnets. | `string` | `""` | no |
| <a name="input_map_public_ip_on_launch"></a> [map\_public\_ip\_on\_launch](#input\_map\_public\_ip\_on\_launch) | Auto-assign public IPs in public subnets. Off by default: load balancers and NAT do not need it, and it prevents accidental exposure of instances. | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | Name prefix applied to every resource (e.g. "acme-dev"). Lowercase letters, digits and hyphens only. | `string` | n/a | yes |
| <a name="input_nat_gateway_mode"></a> [nat\_gateway\_mode](#input\_nat\_gateway\_mode) | NAT strategy for the private tier: "none" (no outbound internet, cheapest), "single" (one shared NAT, cheap but one AZ is a single point of failure), "one\_per\_az" (HA, one NAT and route table per AZ). | `string` | `"single"` | no |
| <a name="input_subnet_netnum_offsets"></a> [subnet\_netnum\_offsets](#input\_subnet\_netnum\_offsets) | Starting cidrsubnet netnum for each tier. AZ index is added to the offset, so offsets must be at least 3 apart to leave room for a third AZ. | <pre>object({<br/>    public   = number<br/>    private  = number<br/>    isolated = number<br/>  })</pre> | <pre>{<br/>  "isolated": 20,<br/>  "private": 10,<br/>  "public": 0<br/>}</pre> | no |
| <a name="input_subnet_newbits"></a> [subnet\_newbits](#input\_subnet\_newbits) | Bits added to the VPC prefix for each subnet (cidrsubnet newbits). 8 on a /16 gives /24 subnets (251 usable IPs each). | `number` | `8` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags merged onto every resource. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_azs"></a> [azs](#output\_azs) | Availability Zones the subnets were placed in, in index order. |
| <a name="output_db_subnet_group_name"></a> [db\_subnet\_group\_name](#output\_db\_subnet\_group\_name) | Name of the RDS DB subnet group, or null if not created. |
| <a name="output_flow_log_group_name"></a> [flow\_log\_group\_name](#output\_flow\_log\_group\_name) | CloudWatch Logs group receiving flow logs, or null if disabled. |
| <a name="output_flow_log_id"></a> [flow\_log\_id](#output\_flow\_log\_id) | ID of the VPC flow log, or null if disabled. |
| <a name="output_flow_log_kms_key_arn"></a> [flow\_log\_kms\_key\_arn](#output\_flow\_log\_kms\_key\_arn) | ARN of the KMS key encrypting the flow log group, or null if disabled. |
| <a name="output_gateway_endpoint_ids"></a> [gateway\_endpoint\_ids](#output\_gateway\_endpoint\_ids) | Map of gateway endpoint service name to endpoint ID. |
| <a name="output_interface_endpoint_ids"></a> [interface\_endpoint\_ids](#output\_interface\_endpoint\_ids) | Map of interface endpoint service name to endpoint ID. |
| <a name="output_interface_endpoint_security_group_id"></a> [interface\_endpoint\_security\_group\_id](#output\_interface\_endpoint\_security\_group\_id) | Security group attached to interface endpoints, or null if none were requested. |
| <a name="output_internet_gateway_id"></a> [internet\_gateway\_id](#output\_internet\_gateway\_id) | ID of the internet gateway. |
| <a name="output_isolated_route_table_id"></a> [isolated\_route\_table\_id](#output\_isolated\_route\_table\_id) | ID of the isolated route table. |
| <a name="output_isolated_subnet_ids"></a> [isolated\_subnet\_ids](#output\_isolated\_subnet\_ids) | IDs of the isolated (database) subnets. These have no route to the internet. |
| <a name="output_nat_gateway_count"></a> [nat\_gateway\_count](#output\_nat\_gateway\_count) | Number of NAT gateways created by the selected nat\_gateway\_mode. |
| <a name="output_nat_gateway_ids"></a> [nat\_gateway\_ids](#output\_nat\_gateway\_ids) | IDs of the NAT gateways (empty when nat\_gateway\_mode = none). |
| <a name="output_nat_public_ips"></a> [nat\_public\_ips](#output\_nat\_public\_ips) | Elastic IPs attached to the NAT gateways - allowlist these with third parties. |
| <a name="output_private_route_table_ids"></a> [private\_route\_table\_ids](#output\_private\_route\_table\_ids) | IDs of the private route tables (one per AZ in one\_per\_az mode, otherwise one). |
| <a name="output_private_subnet_ids"></a> [private\_subnet\_ids](#output\_private\_subnet\_ids) | IDs of the private (application) subnets. |
| <a name="output_public_route_table_id"></a> [public\_route\_table\_id](#output\_public\_route\_table\_id) | ID of the shared public route table. |
| <a name="output_public_subnet_ids"></a> [public\_subnet\_ids](#output\_public\_subnet\_ids) | IDs of the public subnets. |
| <a name="output_subnet_cidrs"></a> [subnet\_cidrs](#output\_subnet\_cidrs) | Computed subnet CIDRs per tier (public, private, isolated), indexed by AZ. |
| <a name="output_vpc_cidr_block"></a> [vpc\_cidr\_block](#output\_vpc\_cidr\_block) | IPv4 CIDR block of the VPC. |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | ID of the VPC. |
<!-- END_TF_DOCS -->
