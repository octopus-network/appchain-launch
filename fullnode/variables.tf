variable "namespace" {
  description = "Namespace"
  type        = string
  default     = "default" # devnet / testnet / mainnet
}

variable "chain_id" {
  description = "Chain ID"
  type        = string
}

variable "chain_name" {
  description = "Chain Name(terraform regex [a-z]([-a-z0-9]*[a-z0-9])?)"
  type        = string
}

variable "nodes" {
  description = "Fullnode Configuration"
  type = object({
    image    = string
    command  = string
    replicas = number

    moniker = string
    genesis = string

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

variable "keys" {
  description = "Fullnode Node Keys"
  type = list(object({
    node_id  = string
    node_key = string
  }))
  sensitive = true
}