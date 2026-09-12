variable "environment_name" {
  description = "Which color this deployment is: blue or green"
  type        = string

  validation {
    condition     = contains(["blue", "green"], var.environment_name)
    error_message = "environment_name must be 'blue' or 'green'."
  }
}

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1" # TODO: set to your region
}
