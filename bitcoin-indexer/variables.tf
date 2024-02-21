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
  default     = "default" # testnet / mainnet
}

variable "dns_zone" {
  description = "DNS zone"
  type        = string
}

# chain
variable "bitcoind" {
  description = "bitcoind node"
  type = object({
    image = string
    chain = string # main, test, signet, regtest
    rpc = object({
      user     = string
      password = string
    })
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

variable "ord" {
  description = "ord index"
  type = object({
    image = string
    chain = string # mainnet, testnet, signet, regtest
    bitcoin = object({
      rpc_user = string
      rpc_pass = string
    })
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

variable "ord_legacy" {
  description = "ord legacy"
  type = object({
    image = string
    chain = string # mainnet, testnet, signet, regtest
    bitcoin = object({
      rpc_user = string
      rpc_pass = string
    })
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
