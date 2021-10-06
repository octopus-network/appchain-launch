variable "kyve" {
  description = "kyve Configuration"
  type = map(object({
    appchain_id = string
    kyve_image  = string
    kyve_files  = string
  }))
}

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