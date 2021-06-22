output "public_ip_address" {
  description = "The public ip of the instance."
  value       = var.create ? (var.bind_eip ? google_compute_address.default.*.address : google_compute_instance.instance.*.network_interface.0.access_config.0.nat_ip) : []
}
