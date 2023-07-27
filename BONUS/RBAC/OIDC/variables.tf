variable "username" {
  type = string
}

variable "password" {
  type = string
}

variable "region" {
  description = "The region of the HCP HVN and Vault cluster."
  type        = string
  default     = "eu-west-2"
}

variable "authmethod" {
  type = string
}


variable "auth0_username" {
  type = string
}

variable "auth0_name" {
  type = string
}

variable "auth0_email" {
  type = string
}

variable "auth0_password" {
  type = string
}