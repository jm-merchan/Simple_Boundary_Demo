variable "username" {
  type = string
}

variable "password" {
  type = string
}

variable "postgres_password" {
  type = string
}

variable "region" {
  description = "The region of the HCP HVN and Vault cluster."
  type        = string
  default     = "eu-west-2"
}

variable "windows_instance_name" {
  type        = string
  description = "EC2 instance name for Windows Server"
  default     = "tfwinsrv01"
}

variable "key_pair_name" {
  type = string
}

variable "authmethod" {
  type = string
}

variable "scenario2_alias_dba" {
  type    = string
  default = "scenario2.dba.boundary.demo"
}

variable "scenario2_alias_dbanalyst" {
  type    = string
  default = "scenario2.dbanalyst.boundary.demo"
}

variable "scenario2_alias_win_rdp" {
  type    = string
  default = "scenario2.winrdp.boundary.demo"
}