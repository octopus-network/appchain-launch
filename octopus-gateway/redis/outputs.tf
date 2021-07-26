
output "host" {
  value = var.create ? google_redis_instance.default.0.host : data.google_redis_instance.default.0.host
}

output "port" {
  value = var.create ? google_redis_instance.default.0.port : data.google_redis_instance.default.0.port
}

output "auth" {
  value = var.create ? google_redis_instance.default.0.auth_string : data.google_redis_instance.default.0.auth_string
  sensitive = true
}

output "cert" {
  value = var.create ? (var.tls_enabled ? google_redis_instance.default.0.server_ca_certs.0.cert : "") : (data.google_redis_instance.default.0.transit_encryption_mode == "SERVER_AUTHENTICATION" ? data.google_redis_instance.default.0.server_ca_certs.0.cert : "")
}
