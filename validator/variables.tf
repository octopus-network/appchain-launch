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
    keyname = string
    keyring = string

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
    mnemonic           = string
    priv_validator_key = string
    node_id            = string
    node_key           = string
  }))
  # sensitive = true
  # validation {
  #   condition     = length(var.validator_keys) == var.validator.replicas
  #   error_message = "The keys list must have the same length as replicas."
  # }
}
