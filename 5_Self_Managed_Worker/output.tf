output "upstreamWorker_publicIP" {
  value = aws_instance.boundary_upstream_worker.public_ip
}

output "upstreamWorker_publicFQDN" {
  value = aws_instance.boundary_upstream_worker.public_dns
}

output "internal-target_privateIP" {
  value = aws_instance.internal_target.private_ip
}

output "connect_ssh" {
  value = "boundary connect ssh -target-id ${boundary_target.ssh.id}"
}

output "connect_ssh_alias" {
  value = "boundary connect ssh ${var.scenario4_alias}"
}

/*
output "targetWindows_creds" {
  value = aws_instance.windows-server.password_data
}

output "boundary_token" {
  value = nonsensitive(vault_token.boundary_token.client_token)
}
*/
