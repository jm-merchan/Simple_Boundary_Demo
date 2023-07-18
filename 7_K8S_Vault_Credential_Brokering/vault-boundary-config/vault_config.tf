resource "vault_policy" "policy_k8s" {
  name = "k8s-policy"

  policy = file("kubernetes_policy.hcl")
}


resource "vault_kubernetes_secret_backend" "config" {
  path                      = "kubernetes"
  description               = "kubernetes secrets engine description"
  default_lease_ttl_seconds = 43200
  max_lease_ttl_seconds     = 86400
  kubernetes_host           = var.kubernetes_host
  kubernetes_ca_cert        = file("ca.crt")
  service_account_jwt       = file("token.txt")
  disable_local_ca_jwt      = true
}

resource "vault_kubernetes_secret_backend_role" "sa-example" {
  backend                       = vault_kubernetes_secret_backend.config.path
  name                          = "my-role"
  allowed_kubernetes_namespaces = ["*"]
  token_max_ttl                 = 43200
  token_default_ttl             = 3600
  service_account_name          = "test-service-account-with-generated-token"

}


resource "vault_token" "boundary_token_k8s" {
  no_default_policy = true
  period            = "20m"
  policies          = ["boundary-controller", "k8s-policy"]
  no_parent         = true
  renewable         = true


  renew_min_lease = 43200
  renew_increment = 86400

  metadata = {
    "purpose" = "service-account-k8s"
  }
}
