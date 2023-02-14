# Configure the AWS Provider
provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment = var.environment
    }
  }
}



resource "aws_ecs_cluster" "cluster" {
  name     = "${var.ecs_cluster_name}-${var.environment}"
}

resource "aws_security_group" "cluster_sg" {
  name        = var.aws_security_group_name
  vpc_id      = var.aws_vpc_id

  ingress {
    description = "Allow HTTP for all"
    from_port   = var.aws_security_group_port
    to_port     = var.aws_security_group_port
    protocol    = var.aws_security_group_protocol
    cidr_blocks = var.aws_security_group_cidr_blocks
  }
}

locals {
  container_definition_app_name = "${var.container_definition_app_name}-${var.environment}"
  app_name = "nodeApp"
}
resource "aws_ecs_cluster_capacity_providers" "cluster" {

  cluster_name = aws_ecs_cluster.cluster.name

  capacity_providers = var.capacity_providers
  default_capacity_provider_strategy {
    capacity_provider = element(var.capacity_providers,0)

  }
}


resource "aws_ecs_task_definition" "node_task_definition" {

  family                   = "service"
  requires_compatibilities = var.capacity_providers
  network_mode             = var.network_mode
  cpu                      = var.cpu
  memory                   = var.memory
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode([
    {
      name      = local.container_definition_app_name
      image     = var.container_definitions_image
      cpu       = var.container_definitions_cpu
      memory    = var.container_definitions_memory
      essential = true
      portMappings = [
        {
          containerPort = var.container_definitions_container_port
          hostPort      = var.container_definitions_host_port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "logs-groups-task-definition"
          awslogs-stream-prefix = "ecs"
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
    aws_iam_role.ecs_task_role,
    aws_iam_role.ecs_task_execution_role
  ]
}

resource "aws_ecs_service" "node-service" {
  name            = "${var.container_definition_app_name}-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.node_task_definition.arn
  desired_count   = var.aws_ecs_service_desired_count
  launch_type     = "FARGATE"
  network_configuration {
    subnets          = var.aws_ecs_service_network_subnets
    security_groups  = [aws_security_group.cluster_sg.id]
    assign_public_ip = true
  }
  depends_on = [
    aws_ecs_cluster.cluster,
    aws_ecs_task_definition.node_task_definition
  ]
}


resource "aws_appautoscaling_target" "autoscaling_target" {
  max_capacity       = 2
  min_capacity       = 1
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.node-service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace = "ecs"
  depends_on = [
    aws_ecs_service.node-service
  ]
}


resource "aws_appautoscaling_policy" "ecs_policy_cpu" {
  name               = "${local.app_name}-${var.environment}-cpu-autoscaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.autoscaling_target.resource_id
  scalable_dimension = aws_appautoscaling_target.autoscaling_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.autoscaling_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 80
  }
  depends_on = [
    aws_appautoscaling_target.autoscaling_target
  ]
}

resource "aws_iam_role" "ecs_task_role" {
name = "role_for_ecs_task_role_${var.container_definition_app_name}-${var.environment}"

assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
            "Service": [
                "ecs.amazonaws.com",
                "ecs-tasks.amazonaws.com"
            ]
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "role_for_ecs_task_exec_${var.container_definition_app_name}-${var.environment}"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
            "Service": [
                "ecs.amazonaws.com",
                "ecs-tasks.amazonaws.com"
            ]
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

resource "aws_iam_policy" "ecs_task_policy" {
name = "policy_for_ecs_${var.container_definition_app_name}-${var.environment}"

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
role       = aws_iam_role.ecs_task_role.name
policy_arn = aws_iam_policy.ecs_task_policy.arn
}