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
    bootnodes = list(string)
    image     = string
    command   = string
    replicas  = number
  }))
}

#
variable "firestore" {
  description = "Firestore Configuration"
  type = object({
    collection = string
  })
}
