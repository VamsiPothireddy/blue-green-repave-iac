variable "aws_region" {
  type    = string
  default = "us-east-1" # TODO: set to your region
}

variable "environment_name" {
  description = "Which color this deployment is: blue or green"
  type        = string
}

variable "resource_prefix" {
  description = "Prefix for resource names (e.g., 'blue' or 'green')"
  type        = string
}

variable "event_source_mapping_enabled" {
  description = "Passed in by the daily-repave workflow: false while this env is mid-repave"
  type        = bool
  default     = true
}

variable "active" {
  description = "Whether this environment is currently active (serving traffic)"
  type        = bool
  default     = false
}
