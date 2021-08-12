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

module "gateway" {
  source         = "./gateway"

  gateway = var.gateway
  redis = {
    host     = module.redis.host
    port     = module.redis.port
    password = module.redis.auth
    tls_cert = module.redis.cert
  }
  etcd = var.etcd
  kafka = var.kafka
}
