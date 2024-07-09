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

# octopus-triggers
variable "triggers" {
  description = "Octopus Triggers Configuration"
  type = object({
    image = string
    resources = object({
      cpu_requests    = string
      cpu_limits      = string
      memory_requests = string
      memory_limits   = string
    })
  })
}

variable "BTC_ENV" {
  description = "BTC_ENV"
  type        = string
}

variable "BTC_CUSTOMS_DEPOSIT_ADDRESS" {
  description = "BTC_CUSTOMS_DEPOSIT_ADDRESS"
  type        = string
}

variable "CANISTERS" {
  description = "CANISTERS"
  type        = string
}

variable "EVM_MONITOR_KEY" {
  description = "EVM_MONITOR_KEY"
  type        = string
}