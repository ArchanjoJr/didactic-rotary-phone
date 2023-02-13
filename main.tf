
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

variable "ecr_name" {
  type  = string
}
module "ecr" {
  source   = "./modules/ecr"
  ecr_name = var.ecr_name
}
variable "ecs_cluster_name" {
  type = string
}
module "ecs" {
  source = "./modules/ecs"
  ecs_cluster_name = var.ecs_cluster_name
  container_definitions_image = module.ecr.ecr_url
}