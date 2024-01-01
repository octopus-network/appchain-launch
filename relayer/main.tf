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

module "hermes" {
  source = "./hermes"

  for_each                = var.relayers
  image                   = each.value.image
  chain_id_1              = each.value.chain_id_1
  chain_id_2              = each.value.chain_id_2
  viewstate_near_endpoint = each.value.viewstate_near_endpoint
  ic_endpoint             = each.value.ic_endpoint
  canister_id             = each.value.canister_id
  canister_pem            = each.value.canister_pem
  ic_credential           = var.relayer_keys[each.key].ic_credential
  credential_1            = var.relayer_keys[each.key].credential_1
  credential_2            = var.relayer_keys[each.key].credential_2
  namespace               = var.namespace
}
