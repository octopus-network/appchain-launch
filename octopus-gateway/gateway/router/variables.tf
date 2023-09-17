variable "namespace" {
  description = "Namespace"
  type        = string
}

variable "gateway_router" {
  description = "Gateway Router Configuration"
  type        = object({
    dns_zone     = string
    replicas     = number
    router_image = string
    resources    = object({
      cpu_requests    = string
      memory_requests = string
    })
  })
}

variable "gateway_router_gprc" {
  description = "Gateway Router gRPC Path"
  type        = list(string)
  default     = [
    "cosmos.authz.v1beta1.Query",
    "cosmos.autocli.v1.Query",
    "cosmos.bank.v1beta1.Query",
    "cosmos.base.node.v1beta1.Service",
    "cosmos.base.reflection.v1beta1.ReflectionService",
    "cosmos.base.reflection.v2alpha1.ReflectionService",
    "cosmos.base.tendermint.v1beta1.Service",
    "cosmos.consensus.v1.Query",
    "cosmos.evidence.v1beta1.Query",
    "cosmos.feegrant.v1beta1.Query",
    "cosmos.gov.v1.Query",
    "cosmos.gov.v1beta1.Query",
    "cosmos.params.v1beta1.Query",
    "cosmos.reflection.v1.ReflectionService",
    "cosmos.slashing.v1beta1.Query",
    "cosmos.staking.v1beta1.Query",
    "cosmos.tx.v1beta1.Service",
    "cosmos.upgrade.v1beta1.Query",
    "grpc.reflection.v1alpha.ServerReflection",
    "ibc.applications.transfer.v1.Query",
    "ibc.core.channel.v1.Query",
    "ibc.core.client.v1.Query",
    "ibc.core.connection.v1.Query",
    "interchain_security.ccv.consumer.v1.Query",
  ]
}
