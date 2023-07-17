
output "target_publicIP" {
  value = aws_instance.ssh_injection_target.public_ip
}

output "target_privateIP" {
  value = aws_instance.ssh_injection_target.private_ip
}

