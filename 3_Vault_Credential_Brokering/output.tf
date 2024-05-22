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
  value = rsadecrypt(aws_instance.windows-server.password_data, file("../2_First_target/${var.key_pair_name}.pem"))
}

output "postgres_dbAdmin_connect" {
  value = "boundary connect postgres -target-id ${boundary_target.dba.id} -dbname northwind"
}

output "postgres_dbAnalyst_connect" {
  value = "boundary connect postgres -target-id ${boundary_target.analyst.id} -dbname northwind"
}

output "rdp_connect" {
  value = "boundary connect rdp -target-id=${boundary_target.win_rdp.id} -exec bash -- -c \"open rdp://full%20address=s={{boundary.addr}} && sleep 6000\""
}


output "postgres_dbAdmin_alias" {
  value = "boundary connect postgres ${var.scenario2_alias_dba} -dbname northwind"
}

output "postgres_dbAnalyst_alias" {
  value = "boundary connect postgres ${var.scenario2_alias_dbanalyst} -dbname northwind"
}

output "rdp_alias" {
  value = "boundary connect rdp ${var.scenario2_alias_win_rdp} -exec bash -- -c \"open rdp://full%20address=s={{boundary.addr}} && sleep 6000\""
}


output "demo_scope" {
  value = data.boundary_scope.org.id
}

