variable "aws_region" {
  type    = string
  default = "us-east-1" # TODO: set to your region
}

variable "event_source_mapping_enabled" {
  description = "Passed in by the daily-repave workflow: false while this env is mid-repave"
  type        = bool
  default     = true
}
