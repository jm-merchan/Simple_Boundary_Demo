resource "boundary_credential_store_static" "example" {
  name        = "example_static_credential_store"
  description = "Credential Store for First Target"
  scope_id    = boundary_scope.project.id
}

resource "boundary_credential_ssh_private_key" "example" {
  name                   = "example_ssh_private_key"
  description            = "My first ssh private key credential!"
  credential_store_id    = boundary_credential_store_static.example.id
  username               = "ubuntu"
  private_key            = file("${var.key_pair_name}.pem") # change to valid SSH Private Key
  depends_on = [ aws_key_pair.ec2_key ]
}