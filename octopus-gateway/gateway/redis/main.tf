
data "google_compute_network" "default" {
  name = "default"
}

data "google_redis_instance" "default" {
  count = var.create ? 0 : 1
  name  = var.name
}

resource "google_redis_instance" "default" {
  count                   = var.create ? 1 : 0
  name                    = var.name
  tier                    = var.tier
  memory_size_gb          = var.memory_size
  region                  = var.region
  redis_version           = var.redis_version
  auth_enabled            = var.auth_enabled
  transit_encryption_mode = var.tls_enabled ? "SERVER_AUTHENTICATION" : "DISABLED"
  authorized_network      = data.google_compute_network.default.id
}
