resource "random_string" "random" {
  count            = 4
  length           = 4
  special          = true
  override_special = "."
  lower            = true
  min_special      = 0
}


resource "auth0_user" "user" {
  for_each = {
    "random1" = random_string.random[0].result
    "random2" = random_string.random[1].result
    "random3" = random_string.random[2].result
    "random4" = random_string.random[3].result
  }
  connection_name = "Username-Password-Authentication"
  name           = "${var.auth0_name}${each.value}"
  email          = "${var.auth0_name}${each.value}@boundaryproject.io"
  email_verified = true
  password       = var.auth0_password
}

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
/*
resource "auth0_action" "my_action" {
  name    = format("Test Action %s", timestamp())
  runtime = "node18"
  deploy  = true
  code    = <<-EOT
    exports.onExecuteCredentialsExchange = async (event, api) => {
    api.accessToken.setCustomClaim('myClaim', 'claim');
   };
  EOT

  supported_triggers {
    id      = "post-login"
    version = "v3"
  }

}
*/