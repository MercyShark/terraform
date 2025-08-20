provider "aws" {
  region = "us-east-1"
}

# --------------------------------------------------------
# 1. Example EC2 instance
# --------------------------------------------------------
resource "aws_instance" "example" {
  ami           = "ami-0c55b159cbfafe1f0" # Example Amazon Linux 2
  instance_type = "t2.micro"
}

# --------------------------------------------------------
# 2. Lambda function (auto zip using archive_file)
# --------------------------------------------------------

# Local lambda source code
# Save this as lambda_function.py in the same directory as your .tf
# def lambda_handler(event, context):
#     print("Event: ", event)
#     return {"statusCode": 200, "body": "Alarm received"}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda_function.py"
  output_path = "${path.module}/lambda.zip"
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "alarm_handler" {
  function_name = "alarm-handler"
  runtime       = "python3.9"
  handler       = "lambda_function.lambda_handler"
  role          = aws_iam_role.lambda_exec_role.arn

  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

# --------------------------------------------------------
# 3. SNS Topic
# --------------------------------------------------------
resource "aws_sns_topic" "alarm_notifications" {
  name = "alarm-notifications"
}

# --------------------------------------------------------
# 4. SNS → Lambda subscription
# --------------------------------------------------------
resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.alarm_notifications.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.alarm_handler.arn
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.alarm_handler.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.alarm_notifications.arn
}

# --------------------------------------------------------
# 5. CloudWatch Alarm
# --------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "cpu_utilization_alarm" {
  alarm_name          = "high-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 70

  alarm_description   = "Triggers if CPU utilization > 70% for 2 minutes"
  actions_enabled     = true

  dimensions = {
    InstanceId = aws_instance.example.id
  }

  alarm_actions = [aws_sns_topic.alarm_notifications.arn]
}
