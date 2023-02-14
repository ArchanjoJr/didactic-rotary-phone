# Configure the AWS Provider
variable "region" {
  default = ""
}
variable "environment" {
  default = ""
}
variable "vpc_cidr" {
  type = string
}
variable "app_name" {
  default = ""
}

variable "private_subnets_cidr" {
  default = ""
}
variable "public_subnets_cidr" {
  default = ""
}
variable "availability_zones" {
  default = ""
}

variable "project" {
  default = ""
}
provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment = var.environment
      Project = var.project
    }
  }
}
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

module "aws_vpc_networking" {
  source = "./modules/vpc_networking"
  region = var.region
  environment = var.environment
  vpc_cidr = var.vpc_cidr
  availability_zones = var.availability_zones
  public_subnets_cidr = var.public_subnets_cidr
  private_subnets_cidr = var.private_subnets_cidr
}

module "ecr" {
  source   = "./modules/ecr"
  ecr_name = "${var.app_name}-repository"
}

module "ecs" {
  source = "./modules/ecs"
  app_name = var.app_name
  private_subnets_ids = module.aws_vpc_networking.private_subnet_id
  public_subnets_ids  = module.aws_vpc_networking.public_subnet_id
  aws_vpc_id = module.aws_vpc_networking.vpc_id
  container_definitions_image = module.ecr.ecr_url
}