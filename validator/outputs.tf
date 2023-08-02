output "persistent_peers" {
  description = "Validator Persistent Peers"
  value       = [for peer in local.persistent_peers : nonsensitive(peer)]
}