output "load_balancer_ip" {
  # value = kubernetes_service.api.status.0.load_balancer.0.ingress.0.ip
  value = google_compute_global_address.api.address
}