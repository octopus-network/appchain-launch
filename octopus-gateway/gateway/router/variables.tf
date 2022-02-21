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
    fluentd_image = string
  })
}

variable "kafka" {
  description = "KAFKA Configuration"
  type        = object({
    hosts = string
    topic = string
    sasl = object({
      mechanisms = string
      username   = string
      password   = string
    })
  })
}
