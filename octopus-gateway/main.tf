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
  source        = "./redis"
  region        = var.region
  tier          = "BASIC"
  redis_version = "REDIS_5_0"
  memory_size   = 1
  auth_enabled  = true
  tls_enabled   = true
}

module "fullnode" {
    source             = "./nodes"
    chain_name         = var.chain_name
    chainspec_url      = var.chainspec_url
    chainspec_checksum = var.chainspec_checksum
    bootnodes          = var.bootnodes
    base_image         = var.base_image
    start_cmd          = var.start_cmd
}

module "gateway" {
    source         = "./gateway"
    redis_host     = module.redis.host
    redis_port     = module.redis.port
    redis_password = module.redis.auth
    redis_cert     = module.redis.cert
}
