output "gateway_fullnode_service" {
  description = "Gateway Fullnode Service"
  value       = {
    "chain": {for k, v in module.fullnode : k => {
      rpc = ["http://${v.service_name}:9933"]
      ws = ["ws://${v.service_name}:9944"]
    }}
  }
}
