variable "relays" {
  description = "Relay Configuration"
  type = map(object({
    node_env                   = string
    appchain_id                = string
    appchain_endpoint          = string
    anchor_contract_id         = string
    relayer_id                 = string
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

# public variable set
variable "APPCHAIN_SETTINGS" {
  description = "APPCHAIN_SETTINGS"
  type        = string
}

variable "CONTRACTS" {
  description = "CONTRACTS"
  type        = string
}

variable "NEAR_SETTINGS" {
  description = "NEAR_SETTINGS"
  type        = string
}

variable "RELAYER_NEAR_ACCOUNT" {
  description = "RELAYER_NEAR_ACCOUNT"
  type        = string
}