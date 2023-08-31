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
    rpc  = "http://${var.chain_name}-fullnode.${var.namespace}:26657"
    grpc = "${var.chain_name}-fullnode.${var.namespace}:9090"
  }
}
