terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

provider "aws" {
    region = "eu-west-2"
}

resource "aws_s3_bucket" "bucket" {
    bucket = "lambda-upload-trigger-lana-2026"
}

resource "aws_iam_role" "lambda_role" {
    name = "lambda-upload-processor-role"
    assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_iam_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "lambda_function" {
    function_name = "lambda-upload-processor"
    role          = aws_iam_role.lambda_role.arn
    handler       = "lambda_function.lambda_handler"
    runtime       = "python3.9"
    filename      = "lambda_function.zip"
}

resource "aws_lambda_permission" "lambda_policy_permission" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}

resource "aws_s3_bucket_notification" "notification" {
  bucket = aws_s3_bucket.bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_function.arn
    events               = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.lambda_policy_permission]
}