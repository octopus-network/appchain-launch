output "fullnode_gateway_service" {
  description = "Fullnode Gateway Service"
  value       = module.fullnode.gateway_service
}

output "fullnode_persistent_peers" {
  description = "Fullnode Persistent Peers"
  value       = module.fullnode.persistent_peers
}

output "validator_persistent_peers" {
  description = "Validator Persistent Peers"
  value       = module.validator.persistent_peers
}
