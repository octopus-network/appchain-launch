variable "namespace" {
  description = "Namespace"
  type        = string
  default     = "default" # devnet / testnet / mainnet
}

# chain
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
  description = "Validator Configuration"
  type = object({
    image    = string
    command  = string
    replicas = number

    moniker = string
    genesis = string
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
  description = "Validator Key"
  type = list(object({
    priv_validator_key = string
    node_id            = string
    node_key           = string
  }))
  sensitive = true
}
