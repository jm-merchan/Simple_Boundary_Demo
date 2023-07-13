# https://portal.cloud.hashicorp.com/

# https://support.hashicorp.com/hc/en-us/articles/4416229422739-HCP-Vault-Upgrade-FAQ

# https://developer.hashicorp.com/vault/tutorials/cloud-ops/terraform-hcp-provider-vault
# https://developer.hashicorp.com/vault/tutorials/cloud-ops/amazon-peering-hcp

resource "hcp_hvn" "learn_hcp_vault_hvn" {
  hvn_id         = var.hvn_id
  cloud_provider = var.cloud_provider
  region         = var.region
}

resource "hcp_vault_cluster" "learn_hcp_vault" {
  hvn_id          = hcp_hvn.learn_hcp_vault_hvn.hvn_id
  cluster_id      = var.vault_cluster_id
  tier            = var.tier
  public_endpoint = true
  metrics_config {
    datadog_api_key = var.datadog_api_key
    datadog_region  = "us1"
  }
  audit_log_config {
    datadog_api_key = var.datadog_api_key
    datadog_region  = "us1"
  }
}

resource "hcp_vault_cluster_admin_token" "token" {
  cluster_id = var.vault_cluster_id
}

