provider "google" {
  project = var.project
  region  = var.region
}

data "google_client_config" "default" {
}

data "google_container_cluster" "default" {
  name     = var.cluster
  location = var.region
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.default.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.default.master_auth[0].cluster_ca_certificate)
}

module "validator" {
  source = "./validator"

  namespace       = var.namespace
  chain_id        = var.chain_id
  ibc_token_denom = var.ibc_token_denom
  enable_gas      = var.enable_gas
  chain_name      = replace(var.chain_id, "_", "-")
  nodes           = var.validator
  keys            = var.validator_keys
}

module "fullnode" {
  source = "./fullnode"

  namespace       = var.namespace
  chain_id        = var.chain_id
  ibc_token_denom = var.ibc_token_denom
  enable_gas      = var.enable_gas
  chain_name      = replace(var.chain_id, "_", "-")
  nodes           = merge(var.fullnode, {peers=module.validator.persistent_peers})
  keys            = var.fullnode_keys

  depends_on = [module.validator]
}