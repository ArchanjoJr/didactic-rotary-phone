output "ecs_cluster_url" {
  value = aws_ecs_cluster.cluster.id
}
output "service_information" {
  value = aws_ecs_service.node-service.id
}
output "sg_info" {
  value = aws_security_group.cluster_sg.id
}