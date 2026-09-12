terraform {
  backend "s3" {
    bucket         = "TODO-your-tfstate-bucket"
    key            = "blue-green-repave-iac/green/terraform.tfstate"
    region         = "us-east-1" # TODO
    dynamodb_table = "TODO-your-tf-lock-table"
    encrypt        = true
  }
}
