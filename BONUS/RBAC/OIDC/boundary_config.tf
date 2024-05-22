data "boundary_scope" "org" {
  name     = "Demo"
  scope_id = "global"
}

data "boundary_scope" "Scenario1_Project" {
  name     = "Scenario1_Project"
  scope_id = data.boundary_scope.org.id
}

data "boundary_scope" "Scenario2_db-project" {
  name     = "Scenario2_db-project"
  scope_id = data.boundary_scope.org.id
}

data "boundary_scope" "Scenario2_win-project" {
  name     = "Scenario2_Windows-project"
  scope_id = data.boundary_scope.org.id
}

data "boundary_scope" "Scenario2_ad-project" {
  name     = "Scenario2b_ad-project"
  scope_id = data.boundary_scope.org.id
}

data "boundary_scope" "Scenario3_ssh-project" {
  name     = "Scenario3_ssh-project"
  scope_id = data.boundary_scope.org.id
}


data "boundary_scope" "Scenario4_ssh-private-project" {
  name     = "Scenario4_ssh-private-project"
  scope_id = data.boundary_scope.org.id
}

data "boundary_scope" "Scenario5_ssh-private-multi-project" {
  name     = "Scenario5_ssh-private-multi-project"
  scope_id = data.boundary_scope.org.id
}

data "boundary_scope" "Scenario5_win-private-multi-project" {
  name     = "Scenario5_win-private-multi-project"
  scope_id = data.boundary_scope.org.id
}

data "boundary_scope" "Scenario6_k8s-project" {
  name     = "Scenario6_k8s-project"
  scope_id = data.boundary_scope.org.id
}

data "boundary_scope" "SSH_Org" {
  name     = "SSH Recording"
  scope_id = "global"
}

data "boundary_scope" "Scenario7_SSH_Recording" {
  name     = "ssh-private-project"
  scope_id = data.boundary_scope.SSH_Org.id
}




# An Auth0 Client loaded using its ID.
data "auth0_client" "boundary" {
  client_id = auth0_client.boundary.client_id
}

data "auth0_tenant" "tenant" {}

resource "boundary_auth_method_oidc" "provider" {
  name                 = "Auth0"
  description          = "OIDC auth method for Auth0"
  scope_id             = "global" #data.boundary_scope.org.id
  issuer               = "https://${data.auth0_tenant.tenant.domain}/"
  client_id            = data.auth0_client.boundary.id
  client_secret        = data.auth0_client.boundary.client_secret
  signing_algorithms   = ["RS256"]
  api_url_prefix       = data.terraform_remote_state.local_backend.outputs.boundary_public_url
  is_primary_for_scope = true
  state                = "active-public"
  max_age              = 0
}

# Configs for Admin User
# ---------------------------
# ---------------------------
resource "boundary_account_oidc" "admin" {
  name           = auth0_user.admin.name
  description    = "Admin user from Auth0"
  auth_method_id = boundary_auth_method_oidc.provider.id
  issuer         = "https://${data.auth0_tenant.tenant.domain}/"
  subject        = auth0_user.admin.user_id
}

resource "boundary_user" "admin" {
  name        = boundary_account_oidc.admin.name
  description = "Admin user from Auth0"
  account_ids = [boundary_account_oidc.admin.id]
  scope_id    = "global" #data.boundary_scope.org.id
}

resource "boundary_role" "admin_org2" {
  # All Permissions for Admin at Project Scope
  name          = "admin-project"
  description   = "Full Admin Permisions at Project level"
  principal_ids = [boundary_user.admin.id]
  grant_strings = ["ids=*;type=*;actions=*"]
  scope_id      = data.boundary_scope.SSH_Org.id
}

resource "boundary_role" "admin_org" {
  name          = "admin-org"
  description   = "Full Admin Permissions at Org level"
  principal_ids = [boundary_user.admin.id]
  grant_strings = ["ids=*;type=*;actions=*"]
  scope_id      = data.boundary_scope.org.id
}

resource "boundary_role" "admin_global" {
  name          = "admin-org"
  description   = "Full Admin Permissions at Global level"
  principal_ids = [boundary_user.admin.id]
  grant_strings = ["ids=*;type=*;actions=*"]
  scope_id      = "global"
}

# ---------------------------
# ---------------------------


# Configs for Linux User
resource "boundary_account_oidc" "linux" {
  name           = auth0_user.linux.name
  description    = "Linux user from Auth0"
  auth_method_id = boundary_auth_method_oidc.provider.id
  issuer         = "https://${data.auth0_tenant.tenant.domain}/"
  subject        = auth0_user.linux.user_id
}

resource "boundary_user" "linux" {
  name        = boundary_account_oidc.linux.name
  description = "Linux user from Auth0"
  account_ids = [boundary_account_oidc.linux.id]
  scope_id    = "global" #data.boundary_scope.org.id
}

resource "boundary_role" "linux1" {
  # Permissions limited to linux target
  name          = "linux1"
  description   = "Access to linux target"
  principal_ids = [boundary_user.linux.id]
  grant_strings = [
    "ids=${var.linux1};actions=authorize-session",
    "ids=*;type=session;actions=read:self,cancel:self,list",
    "ids=*;type=*;actions=read,list"
  ]
  scope_id = data.boundary_scope.Scenario1_Project.id
}
resource "boundary_role" "linux2" {
  # Permissions limited to linux target
  name          = "linux2"
  description   = "Access to linux target"
  principal_ids = [boundary_user.linux.id]
  grant_strings = [
    "ids=${var.linux2};actions=authorize-session",
    "ids=*;type=session;actions=read:self,cancel:self,list",
    "ids=*;type=*;actions=read,list"
  ]
  scope_id = data.boundary_scope.Scenario3_ssh-project.id
}

resource "boundary_role" "linux3" {
  # Permissions limited to linux target
  name          = "linux3"
  description   = "Access to linux target"
  principal_ids = [boundary_user.linux.id]
  grant_strings = [
    "ids=${var.linux3};actions=authorize-session",
    "ids=*;type=session;actions=read:self,cancel:self,list",
    "ids=*;type=*;actions=read,list"
  ]
  scope_id = data.boundary_scope.Scenario4_ssh-private-project.id
}


resource "boundary_role" "linux4" {
  # Permissions limited to linux target
  name          = "linux4"
  description   = "Access to linux target"
  principal_ids = [boundary_user.linux.id]
  grant_strings = [
    "ids=${var.linux4};actions=authorize-session",
    "ids=*;type=session;actions=read:self,cancel:self,list",
    "ids=*;type=*;actions=read,list"
  ]
  scope_id = data.boundary_scope.Scenario5_ssh-private-multi-project.id
}


resource "boundary_role" "linux5" {
  # Permissions limited to linux target
  name          = "linux5"
  description   = "Access to linux target"
  principal_ids = [boundary_user.linux.id]
  grant_strings = [
    "ids=${var.linux5};actions=authorize-session",
    "ids=*;type=session;actions=read:self,cancel:self,list",
    "ids=*;type=*;actions=read,list"
  ]
  scope_id = data.boundary_scope.Scenario7_SSH_Recording.id
}

# ---------------------------
# ---------------------------


# Configs for Linux User
resource "boundary_account_oidc" "http_db" {
  name           = auth0_user.http_db.name
  description    = "HTTP_DB user from Auth0"
  auth_method_id = boundary_auth_method_oidc.provider.id
  issuer         = "https://${data.auth0_tenant.tenant.domain}/"
  subject        = auth0_user.http_db.user_id
}

resource "boundary_user" "http_db" {
  name        = boundary_account_oidc.http_db.name
  description = "http_db user from Auth0"
  account_ids = [boundary_account_oidc.http_db.id]
  scope_id    = "global" #data.boundary_scope.org.id
}

resource "boundary_role" "http_db1" {
  name          = "db1"
  description   = "Access to http or db target"
  principal_ids = [boundary_user.http_db.id]
  grant_strings = [
    "ids=${var.db1};actions=authorize-session",
    "ids=*;type=session;actions=read:self,cancel:self,list",
    "ids=*;type=*;actions=read,list"
  ]
  scope_id = data.boundary_scope.Scenario2_db-project.id
}
resource "boundary_role" "http_db2" {
  name          = "db2"
  description   = "Access to http or db target"
  principal_ids = [boundary_user.http_db.id]
  grant_strings = [
    "ids=${var.db2};actions=authorize-session",
    "ids=*;type=session;actions=read:self,cancel:self,list",
    "ids=*;type=*;actions=read,list"
  ]
  scope_id = data.boundary_scope.Scenario2_db-project.id
}

resource "boundary_role" "http_db3" {
  name          = "http1"
  description   = "Access to http or db target"
  principal_ids = [boundary_user.http_db.id]
  grant_strings = [
    "ids=${var.http1};actions=authorize-session",
    "ids=*;type=session;actions=read:self,cancel:self,list",
    "ids=*;type=*;actions=read,list"
  ]
  scope_id = data.boundary_scope.Scenario2_win-project.id
}

resource "boundary_role" "http_db4" {
  name          = "http2"
  description   = "Access to http or db target"
  principal_ids = [boundary_user.http_db.id]
  grant_strings = [
    "ids=${var.http2};actions=authorize-session",
    "ids=*;type=session;actions=read:self,cancel:self,list",
    "ids=*;type=*;actions=read,list"
  ]
  scope_id = data.boundary_scope.Scenario5_win-private-multi-project.id
}

# ---------------------------
# ---------------------------


# Configs for Windows
resource "boundary_account_oidc" "windows" {
  name           = auth0_user.windows.name
  description    = "windows user from Auth0"
  auth_method_id = boundary_auth_method_oidc.provider.id
  issuer         = "https://${data.auth0_tenant.tenant.domain}/"
  subject        = auth0_user.windows.user_id
}

resource "boundary_user" "windows" {
  name        = boundary_account_oidc.windows.name
  description = "windows user from Auth0"
  account_ids = [boundary_account_oidc.windows.id]
  scope_id    = "global" #data.boundary_scope.org.id
}

resource "boundary_role" "windows1" {
  name          = "windows1"
  description   = "Access to rdp target"
  principal_ids = [boundary_user.windows.id]
  grant_strings = [
    "ids=${var.win1};actions=authorize-session",
    "ids=*;type=session;actions=read:self,cancel:self,list",
    "ids=*;type=*;actions=read,list"
  ]
  scope_id = data.boundary_scope.Scenario2_win-project.id
}
resource "boundary_role" "windows2" {
  name          = "windows2"
  description   = "Access to rdp target"
  principal_ids = [boundary_user.windows.id]
  grant_strings = [
    "ids=${var.win2};actions=authorize-session",
    "ids=*;type=session;actions=read:self,cancel:self,list",
    "ids=*;type=*;actions=read,list"
  ]
  scope_id = data.boundary_scope.Scenario2_ad-project.id
}

resource "boundary_role" "windows3" {
  name          = "windows_ad"
  description   = "Access to rdp target"
  principal_ids = [boundary_user.windows.id]
  grant_strings = [
    "ids=${var.win3};actions=authorize-session",
    "ids=*;type=session;actions=read:self,cancel:self,list",
    "ids=*;type=*;actions=read,list"
  ]
  scope_id = data.boundary_scope.Scenario5_win-private-multi-project.id
}