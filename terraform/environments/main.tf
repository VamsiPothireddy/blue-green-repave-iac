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

module "infra" {
  source            = "../modules/infra"
  environment_name  = var.environment_name
  resource_prefix   = var.resource_prefix
  aws_region        = var.aws_region
}

module "notification_pipeline" {
  source                        = "../modules/notification-pipeline"
  environment_name              = var.environment_name
  resource_prefix               = var.resource_prefix
  event_source_mapping_enabled  = var.event_source_mapping_enabled
  # TODO: pass source_bucket_arn / lambda_execution_role_arn once real values exist
}
