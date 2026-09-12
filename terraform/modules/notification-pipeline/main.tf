# S3 (or EventBridge) -> SQS -> Lambda notification pipeline.
#
# SQS sits between the event source and the Lambda so that during a repave of this
# environment, the event_source_mapping (SQS -> Lambda trigger) can be disabled without
# losing any events — they simply queue up in SQS until it's re-enabled.

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

resource "aws_sqs_queue" "dlq" {
  name                      = "${var.resource_prefix}-notification-dlq"
  message_retention_seconds = 1209600 # 14 days
}

resource "aws_sqs_queue" "buffer" {
  name                       = "${var.resource_prefix}-notification-buffer"
  visibility_timeout_seconds = var.lambda_timeout_seconds * 6 # TODO: tune vs actual Lambda duration
  message_retention_seconds  = 345600                          # 4 days — covers a stuck repave

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })
}

# Allow S3 (or EventBridge, if you swap the source) to publish into the buffer queue.
resource "aws_sqs_queue_policy" "allow_s3" {
  queue_url = aws_sqs_queue.buffer.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowS3Publish"
      Effect    = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.buffer.arn
      Condition = {
        ArnEquals = { "aws:SourceArn" = var.source_bucket_arn } # TODO: set var.source_bucket_arn
      }
    }]
  })
}

# TODO: add the actual S3 bucket notification -> SQS wiring here, e.g.:
# resource "aws_s3_bucket_notification" "this" {
#   bucket = var.source_bucket_id
#   queue { queue_arn = aws_sqs_queue.buffer.arn, events = ["s3:ObjectCreated:*"] }
# }

# The Lambda itself — placeholder. TODO: point `filename`/`s3_key` at your real deployment package.
resource "aws_lambda_function" "processor" {
  function_name = "${var.resource_prefix}-notification-processor"
  role          = var.lambda_execution_role_arn # TODO: pass in a real IAM role ARN
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  timeout       = var.lambda_timeout_seconds
  filename      = var.lambda_package_path # TODO: build + point at lambda/notification_processor

  environment {
    variables = {
      ENVIRONMENT_NAME = var.environment_name
      RESOURCE_PREFIX = var.resource_prefix
    }
  }
}

# The key toggle for repave-safety: this event source mapping is what actually connects
# SQS to the Lambda. The daily-repave workflow disables this (enabled = false) right before
# tearing this environment down, and a fresh one gets created enabled = true on the rebuild.
resource "aws_lambda_event_source_mapping" "sqs_trigger" {
  event_source_arn = aws_sqs_queue.buffer.arn
  function_name     = aws_lambda_function.processor.arn
  enabled           = var.event_source_mapping_enabled
  batch_size        = 10
}
