variable "relays" {
  description = "Relay Configuration"
  type = map(object({
    appchain_id                = string
    appchain_endpoint          = string
    anchor_contract_id         = string
    relayer_private_key        = string
    relayer_image              = string
    start_block_height         = number
    update_state_min_interval  = number
  }))
}

variable "near" {
  description = "Near Configuration"
  type = object({
    node_url   = string
    wallet_url = string
    helper_url = string
  })
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
