# Blue/Green Repave IAC

Daily-rotating blue/green infrastructure. Every day, GitHub Actions repaves (destroys + recreates) whichever environment is currently **inactive**, then flips traffic to it and marks the other one inactive. Over time this gives every environment a fresh rebuild roughly every other day, without ever repaving the environment that's actively serving traffic.

## How it works

1. A scheduled GitHub Actions workflow runs daily (`.github/workflows/daily-repave.yml`).
2. It reads current state (which env is active: `blue` or `green`) from a DynamoDB table.
3. It runs `terraform destroy` + `terraform apply` against the **inactive** environment only.
4. Once the apply succeeds, it flips the DynamoDB state: the just-repaved env becomes `active`, the other becomes `inactive`.
5. Downstream routing (load balancer target group, Route53 weighted record, etc.) reads this same state to send traffic to the active env.

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full design, including why non-LB-fronted event pipelines (S3/EventBridge → Lambda) are routed through SQS instead of calling Lambda directly.

## Structure

```
terraform/
  bootstrap/              # DynamoDB state table (active/inactive tracking) - apply once, manually
  modules/
    infra/                # Placeholder for your actual per-environment infra (EKS, EC2, etc.)
    notification-pipeline/# S3/EventBridge -> SQS -> Lambda, with enable/disable during repave
  environments/
    blue/
    green/
lambda/
  notification_processor/ # Lambda placeholder that polls SQS
scripts/
  state.sh                # Read/write active-environment state from the CLI (for local testing)
.github/workflows/
  daily-repave.yml         # The scheduler
```

## TODO before this is usable

- [ ] Fill in AWS OIDC role ARN in `.github/workflows/daily-repave.yml` (`AWS_ROLE_ARN` placeholder)
- [ ] Fill in Terraform S3 backend bucket/DynamoDB lock table names in `environments/*/backend.tf`
- [ ] Replace `modules/infra/main.tf` placeholder resources with your real infra
- [ ] Decide how traffic actually switches (LB target group swap vs DNS weighted routing) and wire it into the workflow's "activate" step
- [ ] Review the SQS visibility timeout / DLQ settings in `modules/notification-pipeline` against your Lambda's actual runtime
