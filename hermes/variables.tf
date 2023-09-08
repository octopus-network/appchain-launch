variable "namespace" {
  description = "Namespace"
  type        = string
  default     = "default" # devnet / testnet / mainnet
}

variable "nodes" {
  description = "Hermes Relayer Configuration"
  type = object({
    image    = string
    rust_log = string

    resources = object({
      cpu_requests    = string
      cpu_limits      = string
      memory_requests = string
      memory_limits   = string
      volume_type     = string
      volume_size     = string
    })
  })
}

variable "ic_credential" {
  description = "IC Credential"
  type        = string
  sensitive   = true
}

variable "chain_id_1" {
  description = "Chain ID 1"
  type        = string
}

variable "credential_1" {
  description = "Credential 1"
  type        = string
  sensitive   = true
}

variable "chain_id_2" {
  description = "Chain ID 2"
  type        = string
}

variable "credential_2" {
  description = "Credential 2"
  type        = string
  sensitive   = true
}