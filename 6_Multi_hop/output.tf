output "downstreamWorker_publicIP" {
  value = aws_instance.boundary_downstream_worker.public_ip
}

output "internal-target_privateIP" {
  value = aws_instance.internal_target-multi.private_ip
}

output "internal-windows-target_privateIP" {
  value = aws_instance.windows-server.private_ip
}

output "targetWindows_creds_decrypted" {
  value = rsadecrypt(aws_instance.windows-server.password_data, file("../2_First_target/${var.key_pair_name}.pem"))
}
