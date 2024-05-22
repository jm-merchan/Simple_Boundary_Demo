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

variable "scenario3_alias" {
  type        = string
  description = "Alias for first target"
  default = "scenario3.ssh.injected.boundary.demo"
}