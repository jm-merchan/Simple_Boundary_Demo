output "upstreamWorker_publicIP" {
  value = aws_instance.boundary_upstream_worker.public_ip
}

output "internal-target_privateIP" {
  value = aws_instance.internal_target.private_ip
}


/*
output "targetWindows_creds" {
  value = aws_instance.windows-server.password_data
}

output "boundary_token" {
  value = nonsensitive(vault_token.boundary_token.client_token)
}
*/
