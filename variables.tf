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

# chain
variable "chain_id" {
  description = "Chain ID"
  type        = string
}

variable "validator" {
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

variable "validator_keys" {
  description = "Validator Private Key"
  type = list(object({
    mnemonic           = string
    priv_validator_key = string
    node_id            = string
    node_key           = string
  }))
  sensitive = true
  # validation {
  #   condition     = length(var.validator_keys) == var.validator.replicas
  #   error_message = "The keys list must have the same length as replicas."
  # }
}

variable "fullnode" {
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
  # default = {
  #   resources = {
  #     cpu_requests    = "250m"
  #     cpu_limits      = "250m"
  #     memory_requests = "512Mi"
  #     memory_limits   = "512Mi"
  #     volume_type     = "standard-rwo"
  #     volume_size     = "20Gi"
  #   }
  # }
}

variable "fullnode_keys" {
  description = "Fullnode Node Keys"
  type = list(object({
    node_id  = string
    node_key = string
  }))
  sensitive = true
}