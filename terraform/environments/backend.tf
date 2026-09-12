terraform {
  backend "s3" {
    bucket         = "TODO-your-tfstate-bucket"
    key            = "blue-green-repave-iac/terraform.tfstate"
    region         = "us-east-1" # TODO
    dynamodb_table = "TODO-your-tf-lock-table"
    encrypt        = true
    # Note: When using branch-based approach, we'll pass -backend-config to set the key per branch
  }
}
