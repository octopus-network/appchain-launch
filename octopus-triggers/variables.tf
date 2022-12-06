variable "triggers" {
  description = "Octopus Triggers Configuration"
  type = object({
    image          = string
    app_cmd        = optional(string)
    server_cmd     = optional(string)
    listening_port = string
  })
}

variable "triggers_resources" {
  description = "Octopus Score Counter Resources"
  type        = object({
    cpu_requests    = string
    memory_requests = string
  })
  default = {
    cpu_requests    = "150m"
    memory_requests = "256Mi"
  }
}

# postgresql
variable "database" {
  description = "DB Configuration"
  type = object({
    username = string
    password = string
    database = string
    host     = string
    port     = string
  })
}

variable "gce_proxy_image" {
  description = "GCE Proxy Image"
  type        = string
}

variable "gce_proxy_instances" {
  description = "GCE Proxy Instances"
  type        = string
}

variable "gce_proxy_resources" {
  description = "Octopus GCE Proxy Resources"
  type        = object({
    cpu_requests      = string
    memory_requests   = string
  })
  default = {
    cpu_requests    = "100m"
    memory_requests = "256Mi"
  }
}

variable "service_account" {
  description = "Google Service Account"
  type        = string
}

# contract
variable "contract" {
  description = "Contract Configuration"
  type = object({
    network_id                = string
    price_needed_appchain_ids = string
    counting_interval         = number
  })
  sensitive = true
}

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

variable "dns_zone" {
  description = "DNS Zone"
  type        = string
}

# public variable set
variable "APPCHAIN_SETTINGS" {
  description = "APPCHAIN_SETTINGS"
  type        = string
}

variable "CONTRACTS" {
  description = "CONTRACTS"
  type        = string
}

variable "NEAR_SETTINGS" {
  description = "NEAR_SETTINGS"
  type        = string
}

variable "REGISTRY_ADMIN_NEAR_ACCOUNT" {
  description = "REGISTRY_ADMIN_NEAR_ACCOUNT"
  type        = string
}