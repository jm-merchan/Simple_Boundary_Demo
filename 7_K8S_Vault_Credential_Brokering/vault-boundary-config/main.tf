terraform {
  required_providers {

    boundary = {
      source  = "hashicorp/boundary"
      version = "1.1.8"
    }

    vault = {
      source  = "hashicorp/vault"
      version = "3.17.0"
    }
  }
}


# Declare the provider for the HashiCorp Boundary resource to be managed by Terraform
provider "boundary" {
  # Use variables to provide values for the provider configuration
  addr = data.terraform_remote_state.local_backend.outputs.boundary_public_url
  # auth_method_id                  = var.auth_method
  auth_method_login_name = var.username
  auth_method_password   = var.password
}

provider "vault" {
  address = data.terraform_remote_state.local_backend.outputs.vault_public_url
  # token     = var.vault_token
  namespace = "admin" # Set for HCP Vault
}

# Remote Backend to obtain VPC details 
data "terraform_remote_state" "local_backend" {
  backend = "local"

  config = {
    path = "../../1_Plataforma/terraform.tfstate"
  }
}