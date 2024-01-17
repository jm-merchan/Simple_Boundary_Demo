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

variable "key_pair_name" {
  type = string
}

variable "authmethod" {
  type = string
}