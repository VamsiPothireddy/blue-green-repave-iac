terraform {
  backend "s3" {
    bucket         = "TODO-your-tfstate-bucket"
    key            = "blue-green-repave-iac/terraform.tfstate"
    region         = "us-east-1" # TODO
    dynamodb_table = "TODO-your-tf-lock-table"
    encrypt        = true
    # Note: Branch-specific state key is set via -backend-config in workflows
  }
}
