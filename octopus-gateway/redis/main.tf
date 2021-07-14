
data "google_compute_network" "default" {
  name = "default"
}

resource "google_redis_instance" "default" {
  name                    = "octopus-redis"
  tier                    = var.tier
  memory_size_gb          = var.memory_size
  region                  = var.region
  redis_version           = var.redis_version
  auth_enabled            = var.auth_enabled
  transit_encryption_mode = var.tls_enabled ? "SERVER_AUTHENTICATION" : "DISABLED"
  authorized_network      = data.google_compute_network.default.id
}
