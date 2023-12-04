output "blockscout_hosts" {
  description = "Blockscout Hosts"
  value       = kubernetes_manifest.certificate.manifest.spec.domains
}
