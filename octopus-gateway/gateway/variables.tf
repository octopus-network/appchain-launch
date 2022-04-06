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
  })
}

variable "gateway_router" {
  description = "Gateway Router Configuration"
  type        = object({
    dns_zone      = string
    replicas      = number
    router_image  = string
  })
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