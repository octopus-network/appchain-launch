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

module "relayer" {
  source = "./relayer"

  for_each                  = var.relays
  appchain_id               = each.key
  node_env                  = each.value.node_env
  appchain_endpoint         = each.value.appchain_endpoint
  anchor_contract_id        = each.value.anchor_contract_id
  relayer_id                = each.value.relayer_id
  relayer_private_key       = each.value.relayer_private_key
  relayer_image             = each.value.relayer_image
  start_block_height        = each.value.start_block_height
  update_state_min_interval = each.value.update_state_min_interval
  near_node_url             = var.near.node_url
  near_wallet_url           = var.near.wallet_url
  near_helper_url           = var.near.helper_url
  namespace                 = var.namespace
  APPCHAIN_SETTINGS         = var.APPCHAIN_SETTINGS
  CONTRACTS                 = var.CONTRACTS
  NEAR_SETTINGS             = var.NEAR_SETTINGS
  RELAYER_NEAR_ACCOUNT      = var.RELAYER_NEAR_ACCOUNT
}