# Create an organisation scope within global, named "ops-org"
# The global scope can contain multiple org scopes
resource "boundary_scope" "org" {
  scope_id                 = "global"
  name                     = "Demo"
  auto_create_default_role = true
  auto_create_admin_role   = true
}

/* Create a project scope within the "ops-org" organsation
Each org can contain multiple projects and projects are used to hold
infrastructure-related resources
*/
resource "boundary_scope" "project" {
  name                     = "Scenario1_Project"
  description              = "Project Scope"
  scope_id                 = boundary_scope.org.id
  auto_create_admin_role   = true
  auto_create_default_role = true
}

resource "boundary_host_catalog_static" "aws_instance" {
  name        = "Scenario1_Catalog"
  description = "Scenario1"
  scope_id    = boundary_scope.project.id
}

resource "boundary_host_static" "bar" {
  name            = "Scenario1_Public_Facing_EC2_instance"
  host_catalog_id = boundary_host_catalog_static.aws_instance.id
  address         = aws_instance.boundary_target.public_ip
}

resource "boundary_host_set_static" "bar" {
  name            = "Scenario1_Public_Facing_EC2_instance"
  host_catalog_id = boundary_host_catalog_static.aws_instance.id

  host_ids = [
    boundary_host_static.bar.id
  ]
}



resource "boundary_target" "aws_linux_private" {
  type        = "tcp"
  name        = "Scenario1_Public_Facing_EC2_instance"
  description = "AWS Linux Public Facing Target"
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

resource "boundary_alias_target" "scenario1" {
  name           = "Scenario1_Public_Facing_EC2_instance"
  description    = "AWS Linux Public Facing Target"
  scope_id       = "global"
  value          = var.scenario1_alias
  destination_id = boundary_target.aws_linux_private.id
  #authorize_session_host_id = boundary_host_static.bar.id
}
