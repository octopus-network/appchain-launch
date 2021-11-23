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
    image      = string
    command    = string
    chain_spec = string
    replicas   = number
  }))
}

#
variable "firestore" {
  description = "Firestore Configuration"
  type = object({
    collection = string
  })
}
