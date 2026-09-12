# Apply this once, manually, before the daily-repave workflow runs for the first time.
# Creates the DynamoDB table that tracks which environment (blue/green) is currently active.

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

resource "aws_dynamodb_table" "env_state" {
  name         = "blue-green-repave-state"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"

  attribute {
    name = "pk"
    type = "S"
  }

  tags = {
    ManagedBy = "terraform-bootstrap"
    Purpose   = "blue-green-repave-state-tracking"
  }
}

# Seed the initial state: blue active, green inactive.
# (Terraform can't easily seed table items idempotently long-term; this is a one-time convenience.
#  After the first daily-repave run, the workflow owns updates to this item, not Terraform.)
resource "aws_dynamodb_table_item" "initial_state" {
  table_name = aws_dynamodb_table.env_state.name
  hash_key   = aws_dynamodb_table.env_state.hash_key

  item = jsonencode({
    pk              = { S = "env-state" }
    active_env      = { S = "blue" }
    last_repaved_at = { S = timestamp() }
  })

  lifecycle {
    ignore_changes = [item] # workflow updates this outside Terraform after bootstrap
  }
}
