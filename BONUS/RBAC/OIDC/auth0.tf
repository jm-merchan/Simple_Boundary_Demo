resource "auth0_client" "boundary" {
  name                = "Boundary"
  description         = "Boundary"
  app_type            = "regular_web"
  callbacks           = ["${data.terraform_remote_state.local_backend.outputs.boundary_public_url}/v1/auth-methods/oidc:authenticate:callback"]
  allowed_logout_urls = ["${data.terraform_remote_state.local_backend.outputs.boundary_public_url}:3000"]
  oidc_conformant     = true

  jwt_configuration {
    alg = "RS256"
  }
}


resource "auth0_user" "admin" {
  connection_name = "Username-Password-Authentication"
  name            = "Boundary Admin"
  email           = "boundary.admin@boundaryproject.io"
  email_verified  = true
  password        = var.auth0_password
}

resource "auth0_user" "linux" {
  connection_name = "Username-Password-Authentication"
  name            = "Linux User"
  email           = "linux@boundaryproject.io"
  email_verified  = true
  password        = var.auth0_password
}

resource "auth0_user" "windows" {
  connection_name = "Username-Password-Authentication"
  name            = "Windows User"
  email           = "windows@boundaryproject.io"
  email_verified  = true
  password        = var.auth0_password
}

resource "auth0_user" "http_db" {
  connection_name = "Username-Password-Authentication"
  name            = "HTTP and DB User"
  email           = "http_db@boundaryproject.io"
  email_verified  = true
  password        = var.auth0_password
}
