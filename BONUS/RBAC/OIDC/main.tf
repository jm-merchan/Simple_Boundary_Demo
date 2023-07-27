terraform {
  required_providers {
    tls = {
      source  = "hashicorp/tls"
      version = ">=4.0.4"
    }
    boundary = {
      source  = "hashicorp/boundary"
      version = "1.1.9"
    }
    hcp = {
      source  = "hashicorp/hcp"
      version = "0.63.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "5.7.0"
    }
    auth0 = {
      source  = "auth0/auth0"
      version = "1.0.0-beta.0"
    }
  }
}

# Declare the provider for the AWS resource to be managed by Terraform
provider "aws" {
  region = var.region
}

# Declare the provider for the HashiCorp Boundary resource to be managed by Terraform
provider "boundary" {
  # Use variables to provide values for the provider configuration
  addr                   = ""
  auth_method_id         = var.authmethod
  auth_method_login_name = var.username
  auth_method_password   = var.password
}

# Remote Backend to obtain VPC details 
data "terraform_remote_state" "local_backend" {
  backend = "local"

  config = {
    path = "../../../1_Plataforma/terraform.tfstate"
  }
}