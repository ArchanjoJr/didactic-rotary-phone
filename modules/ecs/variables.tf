variable "environment" {
  type        = string
  description = "environment name"
  default     = "dev"
}
variable "region" {
  type        = string
  default     = "us-east-1"
  description = "region name"
}
variable "ecs_cluster_name" {
  type        = any
  description = "name for the ecs_cluster repository"
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
  default = 3000
}
variable "aws_ecs_service_desired_count" {
  default = 1
  type = number
}
variable "aws_ecs_service_network_subnets" {
  type = list(string)
  default = [
    "subnet-6c2ffc21",
    "subnet-fa969aa6",
    "subnet-321d1e55",
    "subnet-cfaba5e1",
    "subnet-132eeb1d",
    "subnet-64e0b75a"
  ]
}
variable "aws_vpc_id" {
  default = "vpc-61550a1b"
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