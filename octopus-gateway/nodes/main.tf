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

module "fullnode" {
  source = "./node"

  for_each        = var.chains
  chain_name      = each.key
  chain_spec      = each.value.chain_spec
  base_image      = each.value.image
  start_cmd       = each.value.command
  replicas        = each.value.replicas
  telemetry_url   = each.value.telemetry_url
  rust_log        = each.value.rust_log
  enable_broker   = try(var.chains_broker[each.key].enable_broker, false)
  secret_phrase   = try(var.chains_broker[each.key].secret_phrase, null)
  cpu_requests    = each.value.resources.cpu_requests
  cpu_limits      = each.value.resources.cpu_limits
  memory_requests = each.value.resources.memory_requests
  memory_limits   = each.value.resources.memory_limits
  volume_type     = each.value.resources.volume_type
  volume_size     = each.value.resources.volume_size
  namespace     = var.namespace
}
