# https://registry.terraform.io/providers/hashicorp/boundary/latest/docs/resources/host_catalog_plugin

# Declare the provider for the HashiCorp Boundary resource to be managed by Terraform
provider "boundary" {
  # Use variables to provide values for the provider configuration
  addr                   = ""
  auth_method_id         = var.authmethod
  auth_method_login_name = var.username
  auth_method_password   = var.password
}

provider "vault" {
  namespace = "admin" # Set for HCP Vault
}

resource "boundary_scope" "org" {
  name                     = "Dynamic Host Catalog Example"
  description              = "Used to demo Boundary capabilities."
  scope_id                 = "global"
  auto_create_admin_role   = true
  auto_create_default_role = true
}

resource "boundary_scope" "project" {
  name                   = "demo_dynamic_host_catalog"
  description            = "Used to demo Boundary dynamic host catalog capabilities."
  scope_id               = boundary_scope.org.id
  auto_create_admin_role = true
}

resource "boundary_host_catalog_plugin" "aws_example" {
  name        = "AWS Sandbox"
  description = "Host catalog in AWS Sandbox"
  scope_id    = boundary_scope.project.id
  plugin_name = "aws"

  attributes_json = jsonencode({
    "region"                      = var.region,
    "disable_credential_rotation" = true
  })
  secrets_json = jsonencode({
    "access_key_id" = aws_iam_access_key.boundary_dynamic_host_catalog.id
    #"access_key_id"     = aws_iam_user.boundary.id
    "secret_access_key" = aws_iam_access_key.boundary_dynamic_host_catalog.secret
    #"secret_access_key" = aws_iam_access_key.secret
  })

  depends_on = [time_sleep.boundary_dynamic_host_catalog_user_ready]

}

resource "boundary_host_set_plugin" "database" {
  name                = "Database host_set_plugin"
  host_catalog_id     = boundary_host_catalog_plugin.aws_example.id
  attributes_json     = jsonencode({ "filters" = ["tag:service-type=database"] })
  preferred_endpoints = ["dns:ec2*"]
}

resource "boundary_host_set_plugin" "dev" {
  name                = "Dev host_set_plugin"
  host_catalog_id     = boundary_host_catalog_plugin.aws_example.id
  attributes_json     = jsonencode({ "filters" = ["tag:application=dev"] })
  preferred_endpoints = ["dns:ec2*"]
}

resource "boundary_host_set_plugin" "production" {
  name                = "production host_set_plugin"
  host_catalog_id     = boundary_host_catalog_plugin.aws_example.id
  attributes_json     = jsonencode({ "filters" = ["tag:application=production"] })
  preferred_endpoints = ["dns:ec2*"]
}

resource "boundary_credential_store_static" "example" {
  name        = "credential_store"
  description = "Credential Store for Dynamic Hosts"
  scope_id    = boundary_scope.project.id
}

resource "boundary_credential_ssh_private_key" "example" {
  name                = "ssh_private_key"
  description         = "ssh private key credential!"
  credential_store_id = boundary_credential_store_static.example.id
  username            = "ubuntu"
  private_key         = file("../../2_First_target/cert.pem") # change to valid SSH Private Key
}

resource "boundary_target" "database" {
  type                     = "tcp"
  name                     = "Dynamic Hosts Database"
  description              = "Dynamic Hosts Database"
  scope_id                 = boundary_scope.project.id
  session_connection_limit = -1
  default_port             = 22
  host_source_ids = [
    boundary_host_set_plugin.database.id,
  ]

  # Comment this to avoid brokeing the credentials
  brokered_credential_source_ids = [
    boundary_credential_ssh_private_key.example.id
  ]
}

resource "boundary_target" "dev" {
  type                     = "tcp"
  name                     = "Dynamic Hosts dev"
  description              = "Dynamic Hosts dev"
  scope_id                 = boundary_scope.project.id
  session_connection_limit = -1
  default_port             = 22
  host_source_ids = [
    boundary_host_set_plugin.dev.id,
  ]

  # Comment this to avoid brokeing the credentials
  brokered_credential_source_ids = [
    boundary_credential_ssh_private_key.example.id
  ]
}

resource "boundary_target" "production" {
  type                     = "tcp"
  name                     = "Dynamic Hosts prod"
  description              = "Dynamic Hosts prod"
  scope_id                 = boundary_scope.project.id
  session_connection_limit = -1
  default_port             = 22
  host_source_ids = [
    boundary_host_set_plugin.production.id,
  ]

  # Comment this to avoid brokeing the credentials
  brokered_credential_source_ids = [
    boundary_credential_ssh_private_key.example.id
  ]
}