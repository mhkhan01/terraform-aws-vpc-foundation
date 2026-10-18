# Runbook

## Prerequisites

- Terraform >= 1.9 (CI uses 1.13.5).
- For real deploys: AWS credentials for the target account (`aws sts get-caller-identity` succeeds) with permissions for EC2/VPC, CloudWatch Logs, KMS and IAM.

## Verify offline (no AWS account)

```bash
make fmt validate test     # or per example:
cd examples/dev && terraform init -backend=false -input=false && terraform test
```

## Deploy

1. Choose the example: `examples/dev` (2 AZs, single NAT) or `examples/prod` (3 AZs, NAT per AZ, endpoints).
2. `cp terraform.tfvars.example terraform.tfvars` and set `cidr_block` to a range that does not overlap any network you will peer or VPN with.
3. Configure a remote backend (see terraform-aws-state-bootstrap) or accept local state for a short test.
4. Run:

   ```bash
   terraform init
   terraform plan -out tfplan
   terraform apply tfplan
   ```

5. Check:

   ```bash
   terraform output subnet_cidrs
   aws ec2 describe-nat-gateways --filter Name=vpc-id,Values=$(terraform output -raw vpc_id) --query 'NatGateways[].State'
   aws logs describe-log-streams --log-group-name "$(terraform output -raw flow_log_group_name)" --max-items 1
   ```

## Change NAT mode

Switching `nat_gateway_mode` from `single` to `one_per_az` adds NAT gateways and per-AZ route tables, then re-points private subnet associations. Expect a few seconds of interrupted egress per subnet during the association swap. Do it in a maintenance window for prod.

## Destroy

```bash
terraform destroy
```

- Destroy fails if other stacks still have ENIs in the subnets (load balancers, RDS, Lambda). Destroy those stacks first.
- The KMS key enters a 30-day pending-deletion window; the alias is removed immediately.
- The flow log group is deleted with its data. Export anything needed for audit first.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|--------------|-----|
| Private instances cannot reach the internet | `nat_gateway_mode = "none"`, or NAT still `pending` | Check `terraform output nat_gateway_count`; wait for NAT state `available` |
| Isolated workload cannot reach an AWS API | By design there is no default route | Use S3/DynamoDB gateway endpoints, add an interface endpoint, or move the workload to the private tier |
| SSM Session Manager cannot connect in prod | Endpoint SG or private DNS | Confirm `ssm`, `ssmmessages`, `ec2messages` endpoints are `available` and the instance SG allows egress 443 to the VPC CIDR |
| `Error: creating Flow Log ... Access Denied for LogDestination` | KMS key policy or IAM role propagation | Re-run apply after a minute; confirm the log group name matches the key policy condition |
| `InvalidSubnet.Conflict` on apply | Overlapping CIDR with an existing VPC subnet (imported or manual) | Change `cidr_block` or `subnet_netnum_offsets` |
| Plan wants to change default NACL `subnet_ids` | Should not happen; `ignore_changes` covers it | Check for a manual NACL association made in the console |
