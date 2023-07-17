# https://portal.cloud.hashicorp.com/

# https://support.hashicorp.com/hc/en-us/articles/4416229422739-HCP-Vault-Upgrade-FAQ

# https://developer.hashicorp.com/vault/tutorials/cloud-ops/terraform-hcp-provider-vault
# https://developer.hashicorp.com/vault/tutorials/cloud-ops/amazon-peering-hcp


resource "hcp_vault_cluster" "hcp_vault" {
  hvn_id          = hcp_hvn.hvn.hvn_id
  cluster_id      = var.vault_cluster_id
  tier            = var.tier
  public_endpoint = true
  /*
  Remove stanzas below if not required
  */
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
  depends_on = [ hcp_vault_cluster.hcp_vault ]
}

