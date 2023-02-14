# Configure the AWS Provider
provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment = var.environment
    }
  }
}

locals {
  HTTP_PROTOCOL = "HTTP"
}

/*====
IAM ROLES FOR ECS
======*/
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "${var.environment}-execution-task-role"
  assume_role_policy = <<EOF
    {
        "Version": "2008-10-17",
        "Statement": [
            {
                "Sid": "",
                "Effect": "Allow",
                "Principal": {
                    "Service": "ecs-tasks.amazonaws.com"
                },
                "Action": "sts:AssumeRole"
            }
        ]
    }
  EOF
}


resource "aws_iam_policy" "ecs_task_policy" {
  name = "policy_for_ecs-${var.environment}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Effect": "Allow",
        "Action": [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:BatchGetImage",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs-task-role-policy-attachment" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}


/*====
ECS CLUSTER
======*/
resource "aws_ecs_cluster" "cluster" {
  name     = "${var.environment}-cluster"
}
resource "aws_ecs_cluster_capacity_providers" "cluster" {

  cluster_name = aws_ecs_cluster.cluster.name

  capacity_providers = var.capacity_providers
  default_capacity_provider_strategy {
    capacity_provider = element(var.capacity_providers,0)

  }
}
/*====
ECS CLUSTER LOG GROUP CONFIGURATION
======*/
resource "aws_cloudwatch_log_group" "log-group" {
  name = "${var.environment}-${var.app_name}-logs"

}
/*====
TASK DEFINITION
======*/
resource "aws_ecs_task_definition" "node_task_definition" {

  family                   = "${var.app_name}-${var.environment}"
  requires_compatibilities = var.capacity_providers
  network_mode             = var.network_mode
  cpu                      = var.cpu
  memory                   = var.memory
  task_role_arn            = aws_iam_role.ecsTaskExecutionRole.arn
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn
  container_definitions = jsonencode([
    {
      name      = "${var.app_name}-${var.environment}-container"
      image     = "${var.container_definitions_image}:latest"
      cpu       = var.container_definitions_cpu
      memory    = var.container_definitions_memory
      essential = true
      portMappings = [
        {
          containerPort = var.container_definitions_container_port
          hostPort      = var.container_definitions_container_port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.log-group.id
          awslogs-stream-prefix = "ecs-${var.environment}-${var.app_name}"
          awslogs-region        = var.region
        }
      }
      healthCheck = {
        retries = 10
        command = [ "CMD-SHELL", "curl --fail http://localhost:3000/status || exit 1"]
        timeout = 5
        interval = 10
        startPeriod = 15
      }
    }
  ])
  depends_on = [
    aws_cloudwatch_log_group.log-group,
    aws_iam_role.ecsTaskExecutionRole
  ]
}


/*====
SERVICE DEFINITION
======*/


resource "aws_ecs_service" "aws-ecs-service" {
  name            = "${var.app_name}-${var.environment}-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.node_task_definition.arn
  force_new_deployment = true
  desired_count   = var.aws_ecs_service_desired_count
  launch_type     = "FARGATE"
  scheduling_strategy = "REPLICA"

  network_configuration {
    subnets          = var.private_subnets_ids
    security_groups  = [
      aws_security_group.service-security-group.id,
      aws_security_group.load_balancer_security_group.id
    ]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.target_group.arn
    container_name = "${var.app_name}-${var.environment}-container"
    container_port = var.container_definitions_container_port
  }
  depends_on = [
    aws_ecs_cluster.cluster,
    aws_ecs_task_definition.node_task_definition
  ]
}

/*====
SECURITY GROUP
======*/

resource "aws_security_group" "service-security-group" {
  name        = "${var.app_name}-${var.environment}-sg"
  vpc_id      = var.aws_vpc_id

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    security_groups = [
      aws_security_group.load_balancer_security_group.id
    ]
  }
  egress {
    from_port = 0
    protocol  = "-1"
    to_port   = 0
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "load_balancer_security_group" {
  vpc_id = var.aws_vpc_id

  ingress {
    from_port        = var.container_definitions_host_port
    to_port          = var.container_definitions_host_port
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

}

/*====
AUTO-SCALING FOR ECS
======*/

resource "aws_appautoscaling_target" "autoscaling_target" {
  max_capacity       = 1
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.aws-ecs-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
  depends_on = [
    aws_ecs_service.aws-ecs-service
  ]
}


resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "${var.app_name}-${var.environment}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.autoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.autoscaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.autoscaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 60
  }
  depends_on = [
    aws_appautoscaling_target.autoscaling_target
  ]
}


/*====
APPLICATION LOAD BALANCER FOR ECS
======*/

resource "aws_alb" "application_load_balancer" {
  name               = "${var.app_name}-${var.environment}-sg"
  internal           = false
  load_balancer_type = var.load_balancer_type
  subnets            = var.public_subnets_ids
  security_groups    = [
    aws_security_group.load_balancer_security_group.id
  ]
}
resource "aws_lb_target_group" "target_group" {
  name        = "${var.app_name}-${var.environment}-tg"
  port        = var.container_definitions_container_port
  protocol    = local.HTTP_PROTOCOL
  target_type = "ip"
  vpc_id      = var.aws_vpc_id

  health_check {
    healthy_threshold   = "3"
    interval            = "300"
    protocol            = local.HTTP_PROTOCOL
    matcher             = "200"
    timeout             = "3"
    path                = "/status"
    unhealthy_threshold = "2"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_alb.application_load_balancer.id
  port              = var.container_definitions_host_port
  protocol          = local.HTTP_PROTOCOL

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group.id
  }
}