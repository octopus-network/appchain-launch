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

module "redis" {
  source = "./redis"

  create        = var.redis.create
  region        = var.redis.region
  name          = var.redis.name
  tier          = var.redis.tier
  redis_version = var.redis.version
  memory_size   = var.redis.memory_size
  auth_enabled  = var.redis.auth_enabled
  tls_enabled   = var.redis.tls_enabled
}

module "fullnode" {
  source = "./nodes"

  for_each      = var.chains
  chain_name    = each.key
  chainspec_url = each.value.chainspec
  bootnodes     = each.value.bootnodes
  base_image    = each.value.image
  start_cmd     = each.value.command
}

locals {
  fullnode = [
    for k, v in module.fullnode : {
      name = k
      service = v.service_name
    }
  ]
}

module "gateway" {
  source         = "./gateway"

  gateway = var.gateway
  chains  = local.fullnode
  redis = {
    host     = module.redis.host
    port     = module.redis.port
    password = module.redis.auth
    tls_cert = module.redis.cert
  }
}
