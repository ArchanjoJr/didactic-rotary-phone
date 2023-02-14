output "ecr_arn" {
  value = aws_ecr_repository.aws-ecr.arn
}
output "ecr_url" {
  value = aws_ecr_repository.aws-ecr.repository_url
}