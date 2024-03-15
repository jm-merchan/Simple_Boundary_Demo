output "target_publicIP" {
  value = aws_instance.boundary_target.public_ip
}
output "ssh_connect" {
  value = "ssh -i cert.pem ubuntu@${aws_instance.boundary_target.public_ip}"
}