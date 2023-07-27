/*
output "target_publicIP" {
  value = aws_instance.boundary_target.public_ip
}
*/

output "usernames" {
  value = toset([
    for user in auth0_user.user : "${user.name}@boundaryproject.io"
  ])
}

output "password" {
  value = var.auth0_password
}

output "auth_method_id" {
  value = boundary_auth_method_oidc.provider.id
}

output "managed-group-id" {
  value = boundary_managed_group.oidc_group.id
}

output "role-id" {
  value = boundary_role.oidc_role.id
}