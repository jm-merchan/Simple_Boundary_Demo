# Create an organisation scope within global, named "ops-org"
# The global scope can contain multiple org scopes
resource "boundary_scope" "org" {
  scope_id                 = "global"
  name                     = "SSH Recording"
  description              = "SSH Team"
  auto_create_default_role = true
  auto_create_admin_role   = true
}

/* Create a project scope within the "ops-org" organsation
Each org can contain multiple projects and projects are used to hold
infrastructure-related resources
*/
resource "boundary_scope" "project" {
  name                     = "ssh-private-project"
  description              = "SSH Recording"
  scope_id                 = boundary_scope.org.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}

resource "vault_token" "boundary_token" {
  no_default_policy = true
  period            = "24h"
  policies          = ["boundary-controller", "ssh"]
  no_parent         = true
  renewable         = true


  renew_min_lease = 43200
  renew_increment = 86400

  metadata = {
    "purpose" = "service-account-boundary-ssh-recording"
  }
}

resource "time_sleep" "boundary_ready" {
  create_duration = "60s"

  depends_on = [aws_instance.boundary_upstream_worker]
}

resource "time_sleep" "boundary_ready2" {
  create_duration = "20s"

  depends_on = [boundary_storage_bucket.aws_example]
}

resource "boundary_storage_bucket" "aws_example" {
  name        = "Storage Bucket"
  description = "My first storage bucket!"
  scope_id    = "global"
  plugin_name = "aws"
  bucket_name = data.terraform_remote_state.local_backend_recording.outputs.bucket_name
  attributes_json = jsonencode({
    "region" = "us-east-1",
  "disable_credential_rotation" : true })

  # recommended to pass in aws secrets using a file() or using environment variables
  # the secrets below must be generated in aws by creating a aws iam user with programmatic access
  secrets_json = jsonencode({
    "access_key_id"     = data.terraform_remote_state.local_backend_recording.outputs.storage_user_access_key_id
    "secret_access_key" = data.terraform_remote_state.local_backend_recording.outputs.storage_user_secret_access_key
  })
  worker_filter = " \"worker_ssh\" in \"/tags/type\" "

  depends_on = [time_sleep.boundary_ready]
}


resource "boundary_credential_store_vault" "vault" {
  name        = "certificates-store"
  description = "My second Vault credential store!"
  # address     = data.terraform_remote_state.local_backend.outputs.vault_public_url
  address   = data.terraform_remote_state.local_backend.outputs.vault_private_url
  token     = vault_token.boundary_token.client_token
  scope_id  = boundary_scope.project.id
  namespace = "admin"
  # Adding worker filter to send request to Vault via Worker, worker that has access to Vault via HVN peering
  worker_filter = " \"worker_ssh\" in \"/tags/type\" "
  # Introducing some delay to let the worker start up
  depends_on = [time_sleep.boundary_ready]
}

resource "boundary_credential_library_vault_ssh_certificate" "ssh" {
  name                = "certificates-library"
  description         = "Certificate Library"
  credential_store_id = boundary_credential_store_vault.vault.id
  path                = "ssh-client-signer/sign/boundary-client" # change to Vault backend path
  username            = "ubuntu"
  key_type            = "ecdsa"
  key_bits            = 521

  extensions = {
    permit-pty = ""
  }
}



resource "boundary_host_catalog_static" "aws_instance" {
  name        = "ssh-catalog-private"
  description = "SSH catalog"
  scope_id    = boundary_scope.project.id
}

resource "boundary_host_static" "ssh" {
  name            = "ssh-host"
  host_catalog_id = boundary_host_catalog_static.aws_instance.id
  address         = aws_instance.internal_target.private_ip
}

resource "boundary_host_set_static" "ssh" {
  name            = "ssh-host-set"
  host_catalog_id = boundary_host_catalog_static.aws_instance.id

  host_ids = [
    boundary_host_static.ssh.id
  ]
}

resource "boundary_target" "ec2" {
  type                     = "ssh"
  name                     = "SSH_Session_Recording_Target"
  description              = "Static Ubuntu"
  scope_id                 = boundary_scope.project.id
  session_connection_limit = -1
  default_port             = 22
  ingress_worker_filter    = " \"worker_ssh\" in \"/tags/type\" "
  host_source_ids = [
    boundary_host_set_static.ssh.id
  ]

  enable_session_recording = true
  storage_bucket_id        = boundary_storage_bucket.aws_example.id

  injected_application_credential_source_ids = [
    boundary_credential_library_vault_ssh_certificate.ssh.id
  ]

  depends_on = [time_sleep.boundary_ready2]
}