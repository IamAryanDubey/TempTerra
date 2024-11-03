provider "aws" {
  region = "us-east-1"
}

resource "random_string" "bucket_suffix" {
  length  = 6
  special = false
}

resource "aws_s3_bucket" "lambda_bucket" {
    bucket = "auto-destroy-lambda-bucket-aryan"
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.lambda_bucket.id
  acl    = "private"
}

resource "aws_iam_role" "lambda_exec" {
  name = "auto_destroy_lambda_exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Effect    = "Allow"
        Sid       = ""
      },
    ]
  })
}

resource "aws_lambda_function" "auto_destroy_function" {
  function_name = "self_destruct_function"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
  s3_bucket     = aws_s3_bucket.lambda_bucket.bucket
  s3_key        = "self_destruct_function.zip"
}

resource "aws_cloudwatch_event_rule" "every_hour" {
  name        = "auto_destroy_every_hour"
  description = "Trigger every hour"
  schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.every_hour.name
  arn       = aws_lambda_function.auto_destroy_function.arn
}

resource "aws_lambda_permission" "allow_events" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auto_destroy_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_hour.arn
}
