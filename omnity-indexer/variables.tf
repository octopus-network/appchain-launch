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


variable "omnity_indexer" {
  description = "omnity indexer"
  type = object({
    image = string
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

variable "sql_proxy" {
  description = "sql proxy"
  type = object({
    image     = string
    instances = string
    database  = string
    resources = object({
      cpu_requests    = string
      cpu_limits      = string
      memory_requests = string
      memory_limits   = string
    })
  })
}

variable "DFX_NETWORK" {
  description = "DFX_NETWORK"
  type        = string
}

variable "DFX_IDENTITY" {
  description = "DFX_IDENTITY"
  type        = string
  sensitive   = true
}

variable "OMNITY_HUB_CANISTER_ID" {
  description = "OMNITY_HUB_CANISTER_ID"
  type        = string
}

variable "OMNITY_CUSTOMS_BITCOIN_CANISTER_ID" {
  description = "OMNITY_CUSTOMS_BITCOIN_CANISTER_ID"
  type        = string
}

variable "OMNITY_ROUTES_ICP_CANISTER_ID" {
  description = "OMNITY_ROUTES_ICP_CANISTER_ID"
  type        = string
}