resource "boundary_scope" "project_w" {
  name                     = "Scenario2_Windows-project"
  description              = "Manage Windows Prod Resources"
  scope_id                 = data.boundary_scope.org.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}

resource "boundary_credential_store_vault" "vault_w" {
  name        = "vault_win"
  description = "My KV"
  address     = data.terraform_remote_state.local_backend.outputs.vault_public_url
  token       = vault_token.boundary_token_kv.client_token
  scope_id    = boundary_scope.project_w.id
  namespace   = "admin"
}

resource "boundary_credential_library_vault" "windows" {
  name                = "Vault KV"
  description         = "Vault KV"
  credential_store_id = boundary_credential_store_vault.vault_w.id
  path                = "secrets/data/windows_secret" # change to Vault backend path
  http_method         = "GET"
}

resource "boundary_host_catalog_static" "aws_instance_w" {
  name        = "Windows Server"
  description = "Windows Server"
  scope_id    = boundary_scope.project_w.id
}

resource "boundary_host_static" "win" {
  name            = "windows-host"
  host_catalog_id = boundary_host_catalog_static.aws_instance_w.id
  address         = aws_instance.windows-server.public_ip
}

resource "boundary_host_set_static" "win" {
  name            = "win-host-set"
  host_catalog_id = boundary_host_catalog_static.aws_instance_w.id

  host_ids = [
    boundary_host_static.win.id
  ]
}

resource "boundary_target" "win_rdp" {
  type                     = "tcp"
  name                     = "Scenario2_Windows-RDP"
  description              = "RDP Target"
  scope_id                 = boundary_scope.project_w.id
  session_connection_limit = -1
  default_port             = 3389
  host_source_ids = [
    boundary_host_set_static.win.id
  ]

  brokered_credential_source_ids = [
    boundary_credential_library_vault.windows.id
  ]

}

resource "boundary_target" "win_http" {
  type                     = "tcp"
  name                     = "Scenario2_Windows-HTTP"
  description              = "HTTP Target"
  scope_id                 = boundary_scope.project_w.id
  session_connection_limit = -1
  default_port             = 80
  host_source_ids = [
    boundary_host_set_static.win.id
  ]
  # Comment this to avoid brokeing the credentials
  /*
  brokered_credential_source_ids = [
    boundary_credential_library_vault.windows.id
  ]
  */
}


resource "boundary_alias_target" "scenario2_win_rdp" {
  name           = "Scenario2_Win_RDP"
  description    = "Scenario2_Win_RDP"
  scope_id       = "global"
  value          = var.scenario2_alias_win_rdp
  destination_id = boundary_target.win_rdp.id
  #authorize_session_host_id = boundary_host_static.bar.id
}