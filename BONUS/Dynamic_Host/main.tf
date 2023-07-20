# Configure the AWS provider
terraform {
  required_providers {
    boundary = {
      source  = "hashicorp/boundary"
      version = "1.1.9"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "4.46.0"
    }
  }
}



