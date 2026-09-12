# Blue/Green Repave IAC

Daily-rotating blue/green infrastructure. Every day, GitHub Actions repaves (destroys + recreates) whichever environment is currently **inactive**, then flips traffic to it and marks the other one inactive. Over time this gives every environment a fresh rebuild roughly every other day, without ever repaving the environment that's actively serving traffic.

## How it works

1. A scheduled GitHub Actions workflow runs daily (`.github/workflows/daily-repave.yml`).
2. It reads current state (which env is active: `blue` or `green`) from a DynamoDB table.
3. It checks out the corresponding git branch (`blue` or `green`) for the inactive environment.
4. It runs `terraform destroy` + `terraform apply` using the appropriate `.tfvars` file (`blue.tfvars` or `green.tfvars`).
5. Once the apply succeeds, it flips the DynamoDB state: the just-repaved env becomes `active`, the other becomes `inactive`.
6. Downstream routing (load balancer target group, Route53 weighted record, etc.) reads this same state to send traffic to the active env.

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full design, including why non-LB-fronted event pipelines (S3/EventBridge → Lambda) are routed through SQS instead of calling Lambda directly.

## Structure

```
terraform/
  bootstrap/              # DynamoDB state table (active/inactive tracking) - apply once, manually
  modules/
    infra/                # Placeholder for your actual per-environment infra (EKS, EC2, etc.)
    notification-pipeline/# S3/EventBridge -> SQS -> Lambda, with enable/disable during repave
  environments/
    main.tf               # Single environment configuration
    variables.tf          # Environment variables
    backend.tf            # Terraform backend configuration
    blue.tfvars           # Blue environment specific configuration
    green.tfvars          # Green environment specific configuration
lambda/
  notification_processor/ # Lambda placeholder that polls SQS
scripts/
  state.sh                # Read/write active-environment state from the CLI (for local testing)
.github/workflows/
  daily-repave.yml         # The scheduler
```

## Branch-based Environment Management

This project uses a branch-based approach for managing blue/green environments:

- **blue branch**: Contains the blue environment configuration and state
- **green branch**: Contains the green environment configuration and state
- **main branch**: Contains the shared infrastructure code

When you want to work on a specific environment:
1. Switch to the corresponding branch: `git checkout blue` or `git checkout green`
2. Run Terraform with the appropriate tfvars file: `terraform plan -var-file=blue.tfvars` or `terraform plan -var-file=green.tfvars`
3. The daily repave workflow automatically switches branches and uses the correct tfvars file

## TODO before this is usable

- [ ] Fill in AWS OIDC role ARN in `.github/workflows/daily-repave.yml` (`AWS_ROLE_ARN` placeholder)
- [ ] Fill in Terraform S3 backend bucket/DynamoDB lock table names in `environments/backend.tf`
- [ ] Replace `modules/infra/main.tf` placeholder resources with your real infra
- [ ] Decide how traffic actually switches (LB target group swap vs DNS weighted routing) and wire it into the workflow's "activate" step
- [ ] Review the SQS visibility timeout / DLQ settings in `modules/notification-pipeline` against your Lambda's actual runtime
- [ ] Create initial blue and green branches: `git checkout -b blue` and `git checkout -b green`
