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


variable "public_key_path" {
}


data "aws_vpc" "default_vpc1" {
  default = true
}

data "aws_subnets" "default_subnet" {
  filter {
    name = "vpc-id"
    values = [ data.aws_vpc.default_vpc1.id ]
  }
}
resource "aws_key_pair" "testing_key_pair" {
  key_name   = "my test key"
  public_key = file(var.public_key_path)
}

resource "aws_security_group" "sg_for_alb" {
    vpc_id = data.aws_vpc.default_vpc1.id
    # ingress {
    #     from_port = 22
    #     to_port = 22
    #     protocol = "tcp"
    #     cidr_blocks = [
    #         var.public_ip_address
    #     ]
    # }
    ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = [ 
        "0.0.0.0/0"
       ]
    }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
  }
}

resource "aws_security_group" "ec2_sg" {
  vpc_id = data.aws_vpc.default_vpc1.id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_for_alb.id] 
  }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [
            "0.0.0.0/0"
        ]
    }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_lb" "app_lb" {
  name               = "my-app-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_for_alb.id]
  subnets = [
    data.aws_subnets.default_subnet.ids[0], data.aws_subnets.default_subnet.ids[1]
  ]
}


resource "aws_lb_target_group" "app_tg" {
  name     = "my-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default_vpc1.id

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}


resource "aws_lb_listener_rule" "error_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority = 30

  condition {
    path_pattern {
      values = ["/error", "/err"]
    }
  }
  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "something went wrong. Please try later!"
      status_code = 400
    }
  }
}


resource "aws_lb_listener_rule" "welcome_rule" {
    listener_arn = aws_lb_listener.http.arn
  priority = 40
  
    condition {
    path_pattern {
      values = ["/welcome", "/wc"]
    }
  }
  action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/html"
      message_body = "<h1>welcome to the page"
      status_code = 200
    }
  }
}


resource "aws_launch_template" "app_lt" {
  name_prefix   = "app-lt"
  image_id      = "ami-0f918f7e67a3323f0" #ubuntu ami
  instance_type = "t2.micro"
  key_name      =  aws_key_pair.testing_key_pair.key_name

  network_interfaces {
    security_groups = [aws_security_group.ec2_sg.id]
  }
user_data = base64encode(<<-EOF
#!/bin/bash
sudo apt update -y
sudo apt install -y nginx
sudo systemctl start nginx
EOF
)


  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "my-asg-instance"
      Environment = "dev"
      Owner       = "Rishabh"
    }
  }
}

resource "aws_lambda_permission" "allow_alb" {
  statement_id  = "AllowExecutionFromALB"
  action        = "lambda:InvokeFunction"
  function_name = "foralb"
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.lambda_tg.arn
}
locals {
  lambda_arn = "arn:aws:lambda:ap-south-1:905418130401:function:foralb"
}

resource "aws_lb_target_group" "lambda_tg" {
  name     = "lambda-tg"
  target_type = "lambda"
  vpc_id   = data.aws_vpc.default_vpc1.id
}

resource "aws_lb_target_group_attachment" "lambda_attactment" {
  target_group_arn = aws_lb_target_group.lambda_tg.arn
  target_id = local.lambda_arn
}

resource "aws_lb_listener_rule" "for_serverless" {
  listener_arn = aws_lb_listener.http.arn
  
  priority = 5
  action { 
      type = "forward"
      target_group_arn = aws_lb_target_group.lambda_tg.arn
  }

  condition { 
    path_pattern { 
        values = [
            "/api*"
        ]
    }
  }
}

resource "aws_autoscaling_group" "app_asg" {
  desired_capacity     = 2
  max_size             = 4
  min_size             = 2
  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }
  target_group_arns = [aws_lb_target_group.app_tg.arn]
  vpc_zone_identifier = [ data.aws_subnets.default_subnet.ids[0]]

   tag {
    key                 = "foo"
    value               = "bar"
    propagate_at_launch = true
  }
}


resource "aws_autoscaling_policy" "scale_out" {
  name = "scale-out"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
}

resource "aws_autoscaling_policy" "scale_in" {
  name                   = "scale-in"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app_asg.name
}


resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 40

  alarm_description   = "This metric monitors EC2 CPU utilization"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_out.arn]
}


resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "cpu-low"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 20

  alarm_description   = "This metric monitors EC2 CPU utilization"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app_asg.name
  }

  alarm_actions = [aws_autoscaling_policy.scale_in.arn]
}



output "lb_dns_name" {
  value = aws_lb.app_lb.dns_name
}


