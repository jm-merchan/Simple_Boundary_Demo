output "target_publicIP" {
  value = aws_instance.boundary_target.public_ip
}
