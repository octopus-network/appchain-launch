# gke
variable "project" {
  description = "Project"
  type        = string
}

variable "region" {
  description = "Region"
  type        = string
}

variable "cluster" {
  description = "Cluster"
  type        = string
}

variable "namespace" {
  description = "Namespace"
  type        = string
  default     = "default" # devnet / testnet / mainnet
}

# gateway
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
  validation {
    condition     = alltrue([for n in var.gateway_router_gprc_hosts : length(n) <= 30])
    error_message = "Each gRPC host must less than or equal to 30 chars"
  }
}

# postgresql
variable "postgresql" {
  description = "PostgreSQL Configuration"
  type        = object({
    database = string
    username = string
    password = string
  })
}

# gateway service account
variable "service_account" {
  description = "Google Service Account"
  type        = string
}