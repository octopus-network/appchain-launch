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

#
variable "chains" {
  description = "Chains Configuration"
  type = map(object({
    image         = string
    command       = string
    chain_spec    = string
    replicas      = number
    telemetry_url = string
    rust_log      = string
    resources     = object({
      cpu_requests    = string
      cpu_limits      = string
      memory_requests = string
      memory_limits   = string
      volume_type     = string
      volume_size     = string
    })
  }))
}

variable "chains_broker" {
  description = "Chains Broker Configuration"
  type = map(object({
    enable_broker = bool
    secret_phrase = string
  }))
  default = {}
  validation {
    condition     = alltrue([
      for k, v in var.chains_broker : 
        v.enable_broker == true ? v.secret_phrase != null : true 
    ])
    error_message = "secret_phrase must be set if enable_broker is true"
  }
  sensitive = true
}
