output "service_name" {
  description = "service name"
  value       = kubernetes_service.default.metadata.0.name
}

output "service_port" {
  description = "service port"
  value       = 3001
}
