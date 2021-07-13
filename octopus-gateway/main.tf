provider "google" {
  project = var.project
  region  = var.region
}

data "google_client_config" "default" {
}

data "google_compute_network" "default" {
  name = "default"
}

resource "google_redis_instance" "default" {
  name                    = "myinstance"
  tier                    = var.redis_tier
  memory_size_gb          = var.redis_memory_size
  region                  = var.region
  redis_version           = var.redis_version
  auth_enabled            = var.redis_auth_enabled
  transit_encryption_mode = var.redis_tls_enabled ? "SERVER_AUTHENTICATION" : "DISABLED"
  authorized_network      = data.google_compute_network.default.id
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

resource "kubernetes_secret" "default" {
  metadata {
    name = "redis-secret"
  }
  data = {
    "redis.password" = google_redis_instance.default.auth_string
    "redis.tls.cert" = google_redis_instance.default.server_ca_certs.0.cert
  }
}
