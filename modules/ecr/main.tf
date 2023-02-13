# Configure the AWS Provider
provider "aws" {
  region = var.region
  default_tags {
    tags = {
      Environment = var.environment
    }
  }
}

resource "aws_ecr_repository" "public_ecr" {
  name                 = "${var.ecr_name}-${var.environment}"
  image_tag_mutability = var.image_tag_mutability
  encryption_configuration {
    encryption_type = var.encryption_type
  }
}