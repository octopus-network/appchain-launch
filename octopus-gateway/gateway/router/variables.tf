variable "namespace" {
  description = "Namespace"
  type        = string
}

variable "gateway_router" {
  description = "Gateway Router Configuration"
  type        = object({
    dns_zone      = string
    replicas      = number
    router_image  = string
  })
}

