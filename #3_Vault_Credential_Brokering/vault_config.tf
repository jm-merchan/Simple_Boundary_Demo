resource "vault_policy" "boundary_controller" {
  name = "boundary-controller"

  policy = file("boundary-controller-policy.hcl")
}

resource "vault_policy" "policy_windows" {
  name = "windows-policy"

  policy = file("windows_static.hcl")
}

resource "vault_mount" "database" {
  path        = "database"
  type        = "database"
  description = "This is an example Database Example"

  default_lease_ttl_seconds = 300
  max_lease_ttl_seconds     = 3600
}

resource "vault_database_secret_backend_connection" "postgres" {
  backend       = vault_mount.database.path
  name          = "postgres"
  allowed_roles = ["dba", "analyst"]

  postgresql {
    connection_url = "postgresql://{{username}}:{{password}}@${aws_instance.postgres_target.public_ip}:5432/postgres?sslmode=disable"
    username       = "vault"
    password       = "vault-password"
  }

}

resource "vault_database_secret_backend_role" "dba" {
  backend             = vault_mount.database.path
  name                = "dba"
  db_name             = vault_database_secret_backend_connection.postgres.name
  creation_statements = [file("dba.sql.hcl")]
}

resource "vault_database_secret_backend_role" "analyst" {
  backend             = vault_mount.database.path
  name                = "analyst"
  db_name             = vault_database_secret_backend_connection.postgres.name
  creation_statements = [file("analyst.sql.hcl")]
}

resource "vault_policy" "northwind_database" {
  name = "northwind-database"

  policy = file("northwind-database-policy.hcl")
}

resource "vault_token" "boundary_token_dba" {
  no_default_policy = true
  period            = "20m"
  policies          = ["boundary-controller", "northwind-database"]
  no_parent         = true
  renewable         = true


  renew_min_lease = 43200
  renew_increment = 86400

  metadata = {
    "purpose" = "service-account-dba"
  }
}

resource "vault_token" "boundary_token_kv" {
  no_default_policy = true
  period            = "20m"
  policies          = ["boundary-controller", "windows-policy"]
  no_parent         = true
  renewable         = true


  renew_min_lease = 43200
  renew_increment = 86400

  metadata = {
    "purpose" = "service-account-kv"
  }
}

# Crear una KVv2 donde añadimos los credenciales de acceso
resource "vault_mount" "kv" {
  path        = "secrets"
  type        = "kv"
  options     = { version = "2" }
  description = "Key-Value Secrets Engine"
}

resource "vault_kv_secret_v2" "windows_secret" {
  mount = vault_mount.kv.path
  name  = "windows_secret"
  data_json = jsonencode(
    {
      "data" : {
        "username" : "Administrator",
        "password" : rsadecrypt(aws_instance.windows-server.password_data, file("../#2_First_target/${var.key_pair_name}.pem"))
      }
    }
  )
}