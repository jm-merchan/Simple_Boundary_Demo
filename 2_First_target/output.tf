output "target_publicIP" {
  value = aws_instance.boundary_target.public_ip
}
output "ssh_connect" {
  value = "ssh -i cert.pem ubuntu@${aws_instance.boundary_target.public_ip}"
}

output "ssh_connect_alias" {
  value = "boundary connect ssh ${var.scenario1_alias}"
}

output "ssh_connect_target-id" {
  value = "boundary connect ssh -target-id ${boundary_target.aws_linux_private.id}"
}