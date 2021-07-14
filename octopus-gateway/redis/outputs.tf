
output "host" {
  value = google_redis_instance.default.host
}

output "port" {
  value = google_redis_instance.default.port
}

output "auth" {
  value = var.auth_enabled ? google_redis_instance.default.auth_string : ""
  sensitive = true
}

output "cert" {
  value = var.tls_enabled ? google_redis_instance.default.server_ca_certs.0.cert : ""
}
