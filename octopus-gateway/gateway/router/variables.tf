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

variable "gateway_router_gprc_hosts" {
  description = "Gateway Router gRPC Hosts"
  type        = list(string)
  default     = []
}
