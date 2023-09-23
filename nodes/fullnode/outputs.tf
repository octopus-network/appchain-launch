output "persistent_peers" {
  description = "Fullnode Persistent Peers"
  value       = [for peer in local.persistent_peers : nonsensitive(peer)]
}

# output "persistent_peers_dns" {
#   description = "Fullnode Persistent Peers"
#   value       = local.persistent_peers_dns
# }

output "gateway_service" {
  description = "Fullnode Service"
  value = {
    for name, port in local.endpoints_service_ports :
    name => "${var.chain_name}-fullnode.${var.namespace}:${port}"
  }
}
