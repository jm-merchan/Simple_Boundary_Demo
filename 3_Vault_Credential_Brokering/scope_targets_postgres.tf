# Create an organisation scope within global, named "ops-org"
# The global scope can contain multiple org scopes
resource "boundary_scope" "org" {
  scope_id                 = "global"
  name                     = "Scenario2_db-scope"
  description              = "DB Team"
  auto_create_default_role = true
  auto_create_admin_role   = true
}

/* Create a project scope within the "ops-org" organsation
Each org can contain multiple projects and projects are used to hold
infrastructure-related resources
*/
resource "boundary_scope" "project" {
  name                     = "Scenario2_db-project"
  description              = "Manage DB Prod Resources"
  scope_id                 = boundary_scope.org.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}

resource "boundary_credential_store_vault" "vault" {
  name        = "vault"
  description = "My first Vault credential store!"
  address     = data.terraform_remote_state.local_backend.outputs.vault_public_url
  token       = vault_token.boundary_token_dba.client_token
  scope_id    = boundary_scope.project.id
  namespace   = "admin"
}

resource "boundary_credential_library_vault" "dba" {
  name                = "northwind dba"
  description         = "northwind dba"
  credential_store_id = boundary_credential_store_vault.vault.id
  path                = "database/creds/dba" # change to Vault backend path
  http_method         = "GET"
}

resource "boundary_credential_library_vault" "analyst" {
  name                = "northwind analyst"
  description         = "northwind analyst"
  credential_store_id = boundary_credential_store_vault.vault.id
  path                = "database/creds/analyst" # change to Vault backend path
  http_method         = "GET"
}

resource "boundary_host_catalog_static" "aws_instance" {
  name        = "db-catalog"
  description = "DB catalog"
  scope_id    = boundary_scope.project.id
}

resource "boundary_host_static" "db" {
  name            = "postgres-host"
  host_catalog_id = boundary_host_catalog_static.aws_instance.id
  address         = aws_instance.postgres_target.public_ip
}

resource "boundary_host_set_static" "db" {
  name            = "db-host-set"
  host_catalog_id = boundary_host_catalog_static.aws_instance.id

  host_ids = [
    boundary_host_static.db.id
  ]
}

resource "boundary_target" "dba" {
  type        = "tcp"
  name        =  "Scenario2_dbAdmin"
  description = "DBA Target"
  #egress_worker_filter     = " \"sm-egress-downstream-worker1\" in \"/tags/type\" "
  #ingress_worker_filter    = " \"sm-ingress-upstream-worker1\" in \"/tags/type\" "
  scope_id                 = boundary_scope.project.id
  session_connection_limit = -1
  default_port             = 5432
  host_source_ids = [
    boundary_host_set_static.db.id
  ]

  # Comment this to avoid brokeing the credentials

  brokered_credential_source_ids = [
    boundary_credential_library_vault.dba.id
  ]

}

resource "boundary_target" "analyst" {
  type                     = "tcp"
  name                     = "Scenario2_dbAnalyst"
  description              = "Analyst Target"
  scope_id                 = boundary_scope.project.id
  session_connection_limit = -1
  default_port             = 5432
  host_source_ids = [
    boundary_host_set_static.db.id
  ]

  # Comment this to avoid brokeing the credentials
  brokered_credential_source_ids = [
    boundary_credential_library_vault.analyst.id
  ]

}

