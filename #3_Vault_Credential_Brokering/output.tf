output "targetLinux_publicIP" {
  value = aws_instance.postgres_target.public_ip
}

output "targetLinux_privateIP" {
  value = aws_instance.postgres_target.private_ip
}


output "targetWindows_publicIP" {
  value = aws_instance.windows-server.public_ip
}

output "targetWindows_privateIP" {
  value = aws_instance.windows-server.private_ip
}

output "targetWindows_creds_decrypted" {
  value = rsadecrypt(aws_instance.windows-server.password_data, file("../#2_First_target/${var.key_pair_name}.pem"))
}



/*
output "targetWindows_creds" {
  value = aws_instance.windows-server.password_data
}

output "boundary_token" {
  value = nonsensitive(vault_token.boundary_token.client_token)
}
*/
