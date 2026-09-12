variable "environment_name" {
  description = "blue or green"
  type        = string
}

variable "source_bucket_arn" {
  description = "ARN of the S3 bucket that publishes notifications into the buffer queue"
  type        = string
  default     = "" # TODO: fill in
}

variable "lambda_execution_role_arn" {
  description = "IAM role ARN the Lambda assumes"
  type        = string
  default     = "" # TODO: fill in
}

variable "lambda_package_path" {
  description = "Path to the zipped Lambda deployment package"
  type        = string
  default     = "../../../lambda/notification_processor/build/processor.zip" # TODO: adjust to your build output
}

variable "lambda_timeout_seconds" {
  type    = number
  default = 30
}

variable "event_source_mapping_enabled" {
  description = "Whether the SQS->Lambda trigger is live. Set false during this environment's repave window."
  type        = bool
  default     = true
}
