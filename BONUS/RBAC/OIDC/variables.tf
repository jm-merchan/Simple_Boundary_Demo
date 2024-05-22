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

variable "linux1" {
  type        = string
  description = "Target ID"
}

variable "linux2" {
  type        = string
  description = "Target ID"
}

variable "linux3" {
  type        = string
  description = "Target ID"
}

variable "linux4" {
  type        = string
  description = "Target ID"
}

variable "linux5" {
  type        = string
  description = "Target ID"
}

variable "win1" {
  type        = string
  description = "Target ID"
}

variable "win2" {
  type        = string
  description = "Target ID"
}

variable "win3" {
  type        = string
  description = "Target ID"
}

variable "db1" {
  type        = string
  description = "Target ID"
}

variable "db2" {
  type        = string
  description = "Target ID"
}

variable "http1" {
  type        = string
  description = "Target ID"
}

variable "http2" {
  type        = string
  description = "Target ID"
}

