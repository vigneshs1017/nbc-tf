####### ECS IAM Role ########
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "${var.name}-execution-task-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  tags = {
    Name        = "${var.name}-iam-role"
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}
####### ECS IAM Role ########

#####  ECR ########
# resource "aws_ecr_repository" "aws-ecr-repo" {
#   name = "${var.name}-ecr"
#   tags = {
#     Name        = "${var.name}-ecr"

#   }
# }
#####  ECR ########

######## ECS Cluster #########
resource "aws_ecs_cluster" "aws-ecs-cluster" {
  name = "${var.name}-cluster"
  tags = {
    Name        = "${var.name}-ecs"
  }
}
######## ECS Cluster #########

######## Cloud Watch Log Group ##########
resource "aws_cloudwatch_log_group" "log-group" {
  name = "${var.name}-logs"
}
######## Cloud Watch Log Group ##########

###### Task Definition #########
# data "template_file" "task_definition" {
#   template               = file("./web_container_definitions")
#   vars = {
#     log_group_region     = var.aws_region
#   }
# }

resource "aws_ecs_task_definition" "ecs_td" {

  family                = "${var.name}-web"
  container_definitions = <<DEFINITION
  [
    {
      "name": "${var.name}-container",
      "image": "919490798061.dkr.ecr.ca-central-1.amazonaws.com/nbc-app:v1",
      "entryPoint": [],
      "essential": true,
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "${aws_cloudwatch_log_group.log-group.id}",
          "awslogs-region": "${var.aws_region}",
          "awslogs-stream-prefix": "${var.name}"
        }
      },
      "portMappings": [
        {
          "containerPort": 8080,
          "hostPort": 8080
        }
      ],
      "cpu": 256,
      "memory": 512,
      "networkMode": "awsvpc"
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = "512"
  cpu                      = "256"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn
}
###### Task Definition #########

#### ALB ###########
resource "aws_alb" "application_load_balancer" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = aws_subnet.publicsubnets.*.id
  security_groups    = [aws_security_group.load_balancer_security_group.id]

  tags = {
    Name        = "${var.name}-alb"
  }
}

resource "aws_lb_target_group" "target_group" {
  name        = "${var.name}-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.nbc_vpc.id

  health_check {
    healthy_threshold   = "3"
    interval            = "300"
    protocol            = "HTTP"
    matcher             = "200"
    timeout             = "3"
    path                = "/"
    unhealthy_threshold = "2"
  }

  tags = {
    Name        = "${var.name}-lb-tg"
  }
}


resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.application_load_balancer.id
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.id
  }
}

# resource "aws_lb_listener_certificate" "my-certificate" {
#   listener_arn = aws_lb_listener.listener.arn
#   certificate_arn = var.load_balancer_certificate
# }

resource "aws_security_group" "load_balancer_security_group" {
  vpc_id = aws_vpc.nbc_vpc.id

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name        = "${var.name}-sg"
  }
}
#### ALB ###########

######## ECS Service ########
resource "aws_security_group" "service_security_group" {
  vpc_id = aws_vpc.nbc_vpc.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.load_balancer_security_group.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name        = "${var.name}-service-sg"
  }
}

resource "aws_ecs_service" "aws-ecs-service" {
  name                 = "${var.name}-ecs-service"
  cluster              = aws_ecs_cluster.aws-ecs-cluster.id
  task_definition      = aws_ecs_task_definition.ecs_td.arn
  launch_type          = "FARGATE"
  scheduling_strategy  = "REPLICA"
  desired_count        = 1
  force_new_deployment = true

  network_configuration {
    subnets          = aws_subnet.privatesubnets.*.id
    assign_public_ip = false
    security_groups = [
      aws_security_group.service_security_group.id,
      aws_security_group.load_balancer_security_group.id
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name   = "${var.name}-container"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.listener]
}

######## ECS AutoScalling #########
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.aws-ecs-cluster.name}/${aws_ecs_service.aws-ecs-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_policy_memory" {
  name               = "${var.name}-memory-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }

    target_value = 80
  }
}

resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "${var.name}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 80
  }
}
######## ECS AutoScalling #########