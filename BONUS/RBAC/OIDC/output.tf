output "password" {
  value = var.auth0_password
}

output "auth_method_id" {
  value = boundary_auth_method_oidc.provider.id
}

output "boundary_authenticate_cli" {
  value = "boundary authenticate oidc -auth-method-id ${boundary_auth_method_oidc.provider.id}"
}


output "linux" {
  value = auth0_user.linux.email
}


output "windows" {
  value = auth0_user.windows.email
}

output "http_db" {
  value = auth0_user.http_db.email
}