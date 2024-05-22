
output "target_publicIP" {
  value = aws_instance.ssh_injection_target.public_ip
}

output "target_privateIP" {
  value = aws_instance.ssh_injection_target.private_ip
}

output "ssh_connect" {
  value = "boundary connect ssh -target-id=${boundary_target.ssh.id}"
}

output "ssh_connect_alias" {
  value = "boundary connect ssh ${var.scenario3_alias}"
}