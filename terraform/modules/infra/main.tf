# PLACEHOLDER module for the actual per-environment infrastructure that gets repaved daily.
# Replace the contents of this module with your real workload (EKS node group, EC2 ASG,
# ECS service, whatever "infrastructure" means for your case) — the module boundary and
# variables below are what the environments/blue and environments/green root modules expect.

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Example placeholder resource so `terraform plan` has something to show.
# TODO: delete this and add your real resources (EKS, EC2, RDS, whatever "infra" is here).
resource "aws_ssm_parameter" "placeholder" {
  name  = "/blue-green-repave/${var.resource_prefix}/placeholder"
  type  = "String"
  value = "replace-me-with-real-infra-${var.resource_prefix}"

  tags = {
    Environment = var.environment_name
    ResourcePrefix = var.resource_prefix
    ManagedBy   = "terraform"
    RepaveGroup = "blue-green"
  }
}
