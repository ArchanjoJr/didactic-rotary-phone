# Configure the AWS Provider
provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment = var.environment
    }
  }
}

resource "aws_ecr_repository" "aws-ecr" {
  name = "${var.environment}-${var.ecr_name}-ecr"
  image_tag_mutability = var.image_tag_mutability
  encryption_configuration {
    encryption_type = var.encryption_type
  }
}