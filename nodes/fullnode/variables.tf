variable "namespace" {
  description = "Namespace"
  type        = string
  default     = "default" # devnet / testnet / mainnet
}

variable "dns_zone" {
  description = "DNS zone"
  type        = string
}

variable "chain_id" {
  description = "Chain ID"
  type        = string
}

variable "ibc_token_denom" {
  description = "IBC token denom"
  type        = string
}

variable "enable_gas" {
  description = "Enable minimum-gas-price"
  type        = bool
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
    peers   = list(string)
    endpoints = map(object({
      options = list(string)
      ports   = list(number)
      expose  = bool
    }))

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
