variable "namespace" {
  description = "Namespace"
  type        = string
}

variable "gateway_api" {
  description = "Gateway API Configuration"
  type        = object({
    replicas       = number
    api_image      = string
    proxy_image    = string
    proxy_instance = string
    resources      = object({
      api_cpu_requests      = string
      api_memory_requests   = string
      proxy_cpu_requests    = string
      proxy_memory_requests = string
    })
  })
}

variable "postgresql" {
  description = "PostgreSQL Configuration"
  type        = object({
    database = string
    username = string
    password = string
  })
}

variable "service_account" {
  description = "Google Service Account"
  type        = string
}
