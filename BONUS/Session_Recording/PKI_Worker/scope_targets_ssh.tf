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

data "aws_caller_identity" "current" {}

data "aws_iam_policy" "demo_user_permissions_boundary" {
  name = "DemoUser"
}

locals {
  my_email = split("/", data.aws_caller_identity.current.arn)[2]
}

# Create the user to be used in Boundary for session recording. Then attach the policy to the user.
resource "aws_iam_user" "boundary_session_recording" {
  name                 = "demo-${local.my_email}-bsr"
  permissions_boundary = data.aws_iam_policy.demo_user_permissions_boundary.arn
  force_destroy        = true
  tags                 = var.common_tags
}

resource "aws_iam_user_policy_attachment" "boundary_session_recording" {
  user       = aws_iam_user.boundary_session_recording.name
  policy_arn = data.aws_iam_policy.demo_user_permissions_boundary.arn
}

data "aws_iam_policy_document" "boundary_user_policy" {
  statement {
    sid = "InteractWithS3"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:GetObjectAttributes",
    ]
    resources = ["arn:aws:s3:::${aws_s3_bucket.storage_bucket.arn}/*"]
  }
  statement {
    actions = [
      "iam:DeleteAccessKey",
      "iam:GetUser",
      "iam:CreateAccessKey"
    ]
    resources = [aws_iam_user.boundary_session_recording.arn]
  }
}

resource "aws_iam_policy" "boundary_user_policy" {
  name        = "demo-${local.my_email}-bsr-policy"
  path        = "/"
  description = "Managed policy for the Boundary user recorder"
  policy      = data.aws_iam_policy_document.boundary_user_policy.json
  tags        = var.common_tags
}


resource "aws_iam_user_policy_attachment" "boundary_user_policy" {
  user       = aws_iam_user.boundary_session_recording.name
  policy_arn = aws_iam_policy.boundary_user_policy.arn
}

# Generate some secrets to pass in to the Boundary configuration.
# WARNING: These secrets are not encrypted in the state file. Ensure that you do not commit your state file!
resource "aws_iam_access_key" "boundary_session_recording" {
  user       = aws_iam_user.boundary_session_recording.name
  depends_on = [aws_iam_user_policy_attachment.boundary_session_recording]
}

# AWS is eventually-consistent when creating IAM Users. Introduce a wait
# before handing credentails off to boundary.
resource "time_sleep" "boundary_session_recording_user_ready" {
  create_duration = "10s"

  depends_on = [aws_iam_access_key.boundary_session_recording]
}

# NOTE:  Be advised, at this time there is no way to delete a storage bucket with the provider or inside of Boundary GUI
# The only way to delete the storage bucket is to delete the cluster at the moment.  As such, you could leverage the below
# to provision a storage bucket with this demo, or you can manage this in your Boundary Cluster Configuration

resource "boundary_storage_bucket" "aws_example" {
  name        = "Storage Bucket"
  description = "My first storage bucket!"
  scope_id    = "global"
  plugin_name = "aws"
  bucket_name = aws_s3_bucket.storage_bucket.id
  attributes_json = jsonencode({
  "region" = "${var.region}",
  "disable_credential_rotation" : true })

  # recommended to pass in aws secrets using a file() or using environment variables
  # the secrets below must be generated in aws by creating a aws iam user with programmatic access
  secrets_json = jsonencode({
    "access_key_id"     = aws_iam_access_key.boundary_session_recording.id,
    "secret_access_key" = aws_iam_access_key.boundary_session_recording.secret
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