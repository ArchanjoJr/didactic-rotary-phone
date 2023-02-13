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
variable "ecr_name" {
  type        = any
  description = "name for the ecr repository"
}

variable "tags" {
  default = {
    Author = "Archanjojr"
  }
  description = "additional tags for aws resources"
  type        = map(string)
}

variable "encryption_type" {
  type    = string
  default = "KMS"
}
variable "image_tag_mutability" {
  type    = string
  default = "MUTABLE"
}