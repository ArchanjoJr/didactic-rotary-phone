variable "environment" {
  type        = string
  description = "environment name"
  default     = "dev"
}
variable "app_name" {}
variable "region" {
  type        = string
  default     = "us-east-1"
  description = "region name"
}

variable "private_subnets_ids" {
  default = ""
}
variable "tags" {
  default = {
    Author = "Archanjojr"
  }
  description = "additional tags for aws resources"
  type        = map(string)
}

variable "capacity_providers" {
  type = list(string)
  default = ["FARGATE"]
}

variable "network_mode" {
  default =  "awsvpc"
}
variable "cpu"{
  default = 1024
}
variable "memory" {
  default = 2048
}
variable "container_definition_app_name" {
  default = "nodeApp"
}
variable "container_definitions_image" {
  default = ""
}
variable "container_definitions_cpu" {
  default = 1024
}
variable "container_definitions_memory" {
  default = 2048
}
variable "container_definitions_container_port" {
  default = 3000
}
variable "container_definitions_host_port" {
  default = 80
}
variable "aws_ecs_service_desired_count" {
  default = 1
  type = number
}

variable "aws_vpc_id" {
  type = string
}
variable "aws_security_group_name" {
  default = "ecs_sg_http"
}
variable "aws_security_group_port" {
  default = 80
  type = number
}
variable "aws_security_group_protocol" {
  default = "tcp"
  type = string
}
variable "aws_security_group_cidr_blocks" {
  default = ["0.0.0.0/0"]
  type = list(string)
}

variable "aws_alb_target_arn" {
  default = ""
}

variable "aws_alb_security_group_id" {
  default = ""
}
variable "load_balancer_type" {
  default = "application"
}
variable "public_subnets_ids" {
  default = ""
}