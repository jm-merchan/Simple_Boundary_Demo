# Create an organisation scope within global, named "ops-org"
# The global scope can contain multiple org scopes
resource "boundary_scope" "org" {
  scope_id                 = "global"
  name                     = "OIDC-org"
  description              = "Support OIDC Creds "
  auto_create_default_role = true
  auto_create_admin_role   = true
}

/* Create a project scope within the "ops-org" organsation
Each org can contain multiple projects and projects are used to hold
infrastructure-related resources
*/
resource "boundary_scope" "project" {
  name                     = "Ops_Production"
  description              = "Manage Prod Resources"
  scope_id                 = boundary_scope.org.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}

# An Auth0 Client loaded using its ID.
data "auth0_client" "boundary" {
  client_id = auth0_client.boundary.client_id
}

data "auth0_tenant" "tenant" {}

resource "boundary_auth_method_oidc" "provider" {
  name                 = "Auth0"
  description          = "OIDC auth method for Auth0"
  scope_id             = boundary_scope.org.id
  issuer               = "https://${data.auth0_tenant.tenant.domain}/"
  client_id            = auth0_client.boundary.client_id
  client_secret        = data.auth0_client.boundary.client_secret
  signing_algorithms   = ["RS256"]
  api_url_prefix       = data.terraform_remote_state.local_backend.outputs.boundary_public_url
  is_primary_for_scope = true
  state                = "active-public"
  max_age              = 0
}

resource "boundary_managed_group" "oidc_group" {
  name           = "Auth0"
  description    = "OIDC managed group for Auth0"
  auth_method_id = boundary_auth_method_oidc.provider.id
  filter         = "\"auth0\" in \"/userinfo/sub\""
}


resource "boundary_account_oidc" "oidc_user" {
  for_each       = auth0_user.user
  name           = each.value.name
  description    = "OIDC account for ${each.value.name}"
  auth_method_id = boundary_auth_method_oidc.provider.id
  issuer         = "https://${data.auth0_tenant.tenant.domain}/" 
  subject        = each.value.user_id
}

resource "boundary_user" "users" {
  for_each    = boundary_account_oidc.oidc_user
  name        = each.value.name
  description = "${each.value.name} user resource"
  account_ids = [each.value.id]
  scope_id    = boundary_scope.org.id
}

resource "boundary_role" "admin" {
  name        = "scope-admin"
  description = "Scope Admin role"
  principal_ids = tolist([
    for user in boundary_user.users : user.id
  ])
  grant_strings = ["id=*;type=*;actions=*"]
  scope_id      = boundary_scope.org.id
}

resource "boundary_role" "oidc_role" {
  name          = "List and Read"
  description   = "List and read role"
  principal_ids = [boundary_managed_group.oidc_group.id]
  grant_strings = ["id=*;type=role;actions=list,read"]
  scope_id      = boundary_scope.org.id
}


resource "boundary_host_catalog_static" "aws_instance" {
  name        = "Simple_Catalog"
  description = "Simple catalog"
  scope_id    = boundary_scope.project.id
}
/*

resource "boundary_host_static" "bar" {
  name            = "aws-private-linux"
  host_catalog_id = boundary_host_catalog_static.aws_instance.id
  address         = aws_instance.boundary_target.public_ip
}

resource "boundary_host_set_static" "bar" {
  name            = "aws-private-linux"
  host_catalog_id = boundary_host_catalog_static.aws_instance.id

  host_ids = [
    boundary_host_static.bar.id
  ]
}

resource "boundary_target" "aws_linux_private" {
  type        = "tcp"
  name        = "aws-private-linux"
  description = "AWS Linux Private Target"
  #egress_worker_filter     = " \"sm-egress-downstream-worker1\" in \"/tags/type\" "
  #ingress_worker_filter    = " \"sm-ingress-upstream-worker1\" in \"/tags/type\" "
  scope_id                 = boundary_scope.project.id
  session_connection_limit = -1
  default_port             = 22
  host_source_ids = [
    boundary_host_set_static.bar.id
  ]

  # Comment this to avoid brokeing the credentials
  brokered_credential_source_ids = [
    boundary_credential_ssh_private_key.example.id
  ]

}
*/
