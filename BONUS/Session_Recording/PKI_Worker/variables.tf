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

resource "random_id" "foo_key" {
  prefix      = "foo"
  byte_length = 4
}

resource "random_id" "qux_key" {
  prefix      = "qux"
  byte_length = 4
}

resource "random_id" "bar_key" {
  prefix      = "bar"
  byte_length = 4
}

resource "random_id" "baz_key" {
  prefix      = "baz"
  byte_length = 4
}

locals {
  hashicorp_email = split(":", data.aws_caller_identity.current.user_id)[1]
  instance_tags = [
    {
      "${random_id.foo_key.dec}" = "test",
      "${random_id.qux_key.dec}" = "true",
    },
    {
      "${random_id.foo_key.dec}" = "prod",
      "${random_id.bar_key.dec}" = "true",
      "${random_id.qux_key.dec}" = "true",
    },
    {
      "${random_id.bar_key.dec}" = "true",
      "${random_id.qux_key.dec}" = "true",
    },
    {
      "${random_id.bar_key.dec}" = "true",
      "${random_id.baz_key.dec}" = "true",
      "${random_id.qux_key.dec}" = "true",
    },
    {
      "${random_id.baz_key.dec}" = "true",
      "${random_id.qux_key.dec}" = "true",
    },
  ]
}

variable "common_tags" {
  type        = map(string)
  description = "Map of common tags for all taggable AWS resources."
  default     = {}
}