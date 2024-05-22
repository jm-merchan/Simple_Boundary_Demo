variable "username" {
  type = string
}

variable "password" {
  type = string
}

variable "kubernetes_host" {
  type = string
}

variable "authmethod" {
  type = string
}

variable "scenario6_alias" {
  type = string
  default = "scenario6.k8s.boundary.demo"
}