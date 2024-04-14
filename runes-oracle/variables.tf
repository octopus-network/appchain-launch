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

# pod
variable "runes_oracle" {
  description = "Runes Oracle Configuration"
  type = object({
    image    = string
    replicas = number

    resources = object({
      cpu_requests    = string
      cpu_limits      = string
      memory_requests = string
      memory_limits   = string
    })
  })
}

# env variables
variable "INDEXER_URL" {
  description = "INDEXER_URL"
  type        = string
}

variable "IC_GATEWAY" {
  description = "IC_GATEWAY"
  type        = string
}

variable "CUSTOMS_CANISTER_ID" {
  description = "CUSTOMS_CANISTER_ID"
  type        = string
}

variable "PEM_PATH" {
  description = "PEM_PATH"
  type        = string
}

variable "identity_pem" {
  description = "identity_pem"
  type        = string
  sensitive   = true
}