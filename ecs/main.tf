provider "aws" {
  region = "ap-south-1"
  profile = "sova-profile"
}

data "aws_vpc" "main" {
  default = true
}

resource "aws_ecs_cluster" "main" {
  name = "ecs-cluster"
}

resource "aws_iam_role" "ecs_task_exec" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_exec_policy" {
  role       = aws_iam_role.ecs_task_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "app" {
  family                   = "my-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512

  execution_role_arn = aws_iam_role.ecs_task_exec.arn
  container_definitions = jsonencode([
    {
      name      = "my-container"
      image     = "nginx:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_security_group" "ecs_sg" {
  vpc_id = data.aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ecs-sg" }
}

data "aws_subnets" "public" {
    filter {
      name = "vpc-id"
      values = [data.aws_vpc.main.id]
    }
}


resource "aws_lb" "app_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_sg.id]
  subnets            = data.aws_subnets.public.ids

  enable_deletion_protection = false
}

resource "aws_lb_target_group" "app_tg" {
  name     = "my-ecs-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.main.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "app_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"
    
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_ecs_service" "api_service" {
  name            = "my-api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.app.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [data.aws_subnets.public.ids[0]]
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

    load_balancer {
        target_group_arn = aws_lb_target_group.app_tg.arn
        container_name   = "my-container"
        container_port   = 80
    }   

    depends_on = [ aws_ecs_cluster.main, aws_lb_listener.app_listener ]

}


output "alb_dns_name" {
  value = aws_lb.app_alb.dns_name
}