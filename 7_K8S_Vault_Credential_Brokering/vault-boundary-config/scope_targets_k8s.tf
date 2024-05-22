data "boundary_scope" "org" {
  name     = "Demo"
  scope_id = "global"
}

resource "boundary_scope" "project" {
  name                     = "Scenario6_k8s-project"
  description              = "Manage k8s Resources"
  scope_id                 = data.boundary_scope.org.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}

resource "boundary_credential_store_vault" "vault" {
  name        = "vault"
  description = "Vault Credential Store for Kubernetes access"
  # Connecting via peering
  address   = data.terraform_remote_state.local_backend.outputs.vault_private_url
  token     = vault_token.boundary_token_k8s.client_token
  scope_id  = boundary_scope.project.id
  namespace = "admin"
  # Connecting via peering
  worker_filter = " \"worker1\" in \"/tags/type\" "
}

resource "boundary_credential_library_vault" "k8s_full" {
  name                = "Test Namespace"
  description         = "Account for test namespace"
  credential_store_id = boundary_credential_store_vault.vault.id
  path                = "kubernetes/creds/my-role" # change to Vault backend path
  http_method         = "POST"
  http_request_body   = <<EOT
    {
      "kubernetes_namespace": "test"
    }
    EOT
}


resource "boundary_host_catalog_static" "k8s" {
  name        = "k8s"
  description = "k8s catalog"
  scope_id    = boundary_scope.project.id
}

# Remove https part from EKS host URL
locals {
  url_without_protocol = replace(var.kubernetes_host, "https://", "")
}

resource "boundary_host_static" "k8s" {
  name            = "EKS Endpoint"
  host_catalog_id = boundary_host_catalog_static.k8s.id
  address         = local.url_without_protocol
}


resource "boundary_host_set_static" "k8s" {
  name            = "k8s-host-set"
  host_catalog_id = boundary_host_catalog_static.k8s.id

  host_ids = [
    boundary_host_static.k8s.id
  ]
}

resource "boundary_target" "k8s" {
  type        = "tcp"
  name        = "Scenario6_EKSCluster"
  description = "Access to test namespace"

  scope_id                 = boundary_scope.project.id
  session_connection_limit = -1
  default_port             = 443
  host_source_ids = [
    boundary_host_set_static.k8s.id
  ]

  # Comment this to avoid brokeing the credentials

  brokered_credential_source_ids = [
    boundary_credential_library_vault.k8s_full.id
  ]

}

resource "boundary_alias_target" "scenario6_k8s" {
  name           = "scenario6_k8s"
  description    = "scenario6_k8s"
  scope_id       = "global"
  value          = var.scenario6_alias
  destination_id = boundary_target.k8s.id
  #authorize_session_host_id = boundary_host_static.bar.id
}