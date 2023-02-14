variable "vpc_cidr" {
  default = ""
}
variable "environment" {
  default = "dev"
}
variable "region" {
  type        = string
  default     = "us-east-1"
  description = "region name"
}
variable "availability_zones" {
  default = ""
}
variable "public_subnets_cidr" {
  default = ""
}
variable "private_subnets_cidr" {
  default = ""
}