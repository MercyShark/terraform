terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

variable "smtp_user" {
}
variable "smtp_password" {
}
variable "sender_email" {
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Attach AWSLambdaBasicExecutionRole policy
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda Function
resource "aws_lambda_function" "my_lambda" {
  function_name = "my_terraform_lambda"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"

  filename         = "${path.module}/function.zip"
  source_code_hash = filebase64sha256("${path.module}/function.zip")

  timeout = 10
  environment {
    variables = {
      SMTP_USER = var.smtp_user
      SMTP_PASSWORD = var.smtp_password
      SENDER_EMAIL  = var.sender_email
    }
  }
}


resource "aws_lambda_function_url" "my_lambda_url" {
    function_name = aws_lambda_function.my_lambda.function_name
    authorization_type = "NONE"
}

output "function_url" {
  value = aws_lambda_function_url.my_lambda_url.function_url
}