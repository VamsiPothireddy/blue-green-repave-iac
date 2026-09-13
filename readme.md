# Blue/Green Repave IAC

Daily-rotating blue/green infrastructure. Every day, GitHub Actions repaves (destroys + recreates) whichever environment is currently **inactive**, then flips traffic to it and marks the other one inactive. Over time this gives every environment a fresh rebuild roughly every other day, without ever repaving the environment that's actively serving traffic.

## How it works

### Regular Deployments
1. When you push to the `blue` branch, the deploy workflow (`.github/workflows/deploy.yml`) triggers
2. It uses the `config.tfvars` file on the blue branch which contains blue-specific configuration
3. Terraform deploys/updates the blue environment resources
4. Similarly, pushing to the `green` branch deploys the green environment using its `config.tfvars`

### Daily Repave
1. A scheduled GitHub Actions workflow runs daily (`.github/workflows/daily-repave.yml`).
2. It reads current state (which env is active: `blue` or `green`) from the `active` variable in the `config.tfvars` file on each branch.
3. It checks out the inactive environment's branch.
4. It runs `terraform destroy` + `terraform apply` using that branch's `config.tfvars` file.
5. Once the apply succeeds, it flips the `active` status in both branches' `config.tfvars` files: the just-repaved env becomes `active = true`, the other becomes `active = false`.
6. Downstream routing (load balancer target group, Route53 weighted record, etc.) can read the config files or use other methods to send traffic to the active env.

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full design, including why non-LB-fronted event pipelines (S3/EventBridge → Lambda) are routed through SQS instead of calling Lambda directly.

## Structure

```
terraform/
  modules/
    infra/                # Placeholder for your actual per-environment infra (EKS, EC2, etc.)
    notification-pipeline/# S3/EventBridge -> SQS -> Lambda, with enable/disable during repave
  environments/
    main.tf               # Single environment configuration
    variables.tf          # Environment variables
    backend.tf            # Terraform backend configuration
    config.tfvars         # Environment-specific configuration (single file, content varies by branch)
lambda/
  notification_processor/ # Lambda placeholder that polls SQS
scripts/
  init-branches.sh        # Helper script to initialize blue and green branches
.github/workflows/
  deploy.yml              # Branch-based deployment trigger
  daily-repave.yml         # The scheduler
```

## Branch-based Environment Management

This project uses a branch-based approach for managing blue/green environments with file-based state:

- **blue branch**: Contains blue-specific `config.tfvars` with `active = true/false` and blue resource names
- **green branch**: Contains green-specific `config.tfvars` with `active = true/false` and green resource names
- **main branch**: Contains the shared infrastructure code (no config.tfvars)

State is managed through the `active` variable in each branch's `config.tfvars` file:
- `active = true` indicates the environment is currently serving traffic
- `active = false` indicates the environment is inactive and can be repaved

### Regular Deployments
When you want to work with a specific environment:
1. Switch to the corresponding branch: `git checkout blue` or `git checkout green`
2. Make changes to the branch
3. Push to trigger automatic deployment: `git push origin blue` or `git push origin green`
4. The deploy workflow automatically uses the branch's `config.tfvars` file

### Daily Repave
The daily repave workflow automatically:
- Checks which branch has `active = true` in its `config.tfvars`
- Repaves the inactive environment branch
- Flips the `active` status in both branches' `config.tfvars` files

## TODO before this is usable

- [ ] Fill in AWS OIDC role ARN in `.github/workflows/deploy.yml` and `.github/workflows/daily-repave.yml` (`AWS_ROLE_ARN` placeholder)
- [ ] Fill in Terraform S3 backend bucket/DynamoDB lock table names in `environments/backend.tf`
- [ ] Replace `modules/infra/main.tf` placeholder resources with your real infra
- [ ] Decide how traffic actually switches (LB target group swap vs DNS weighted routing) and wire it into the workflow's "activate" step
- [ ] Review the SQS visibility timeout / DLQ settings in `modules/notification-pipeline` against your Lambda's actual runtime
- [ ] Run `./scripts/init-branches.sh` to create blue and green branches with their own config.tfvars files
