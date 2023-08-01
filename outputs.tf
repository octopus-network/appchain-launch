output "fullnode_gateway_service" {
  description = "Gateway Gateway Service"
  value       = module.fullnode.gateway_service
}

output "fullnode_persistent_peers" {
  description = "Gateway Persistent Peers"
  value       = module.fullnode.persistent_peers
}
