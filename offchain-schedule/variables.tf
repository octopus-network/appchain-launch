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
variable "offchain_schedule" {
  description = "Offchain Schedule Configuration"
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
variable "NEAR_ENV" {
  description = "NEAR_ENV"
  type        = string
  default     = "testnet"
}

variable "NEAR_CLI_TESTNET_RPC_SERVER_URL" {
  description = "NEAR_CLI_TESTNET_RPC_SERVER_URL"
  type        = string
  default     = "https://rpc.testnet.near.org"
}

variable "NEAR_CLI_MAINNET_RPC_SERVER_URL" {
  description = "NEAR_CLI_MAINNET_RPC_SERVER_URL"
  type        = string
  default     = "https://rpc.mainnet.near.org"
}

variable "SCHEDULE_SIGNER" {
  description = "SCHEDULE_SIGNER"
  type        = string
}

variable "SCHEDULE_SIGNER_SECRET_KEY" {
  description = "SCHEDULE_SIGNER_SECRET_KEY"
  type        = string
  sensitive   = true
}

variable "LPOS_MARKET_CONTRACT" {
  description = "LPOS_MARKET_CONTRACT"
  type        = string
}

variable "APPCHAIN_REGISTRY_CONTRACT" {
  description = "APPCHAIN_REGISTRY_CONTRACT"
  type        = string
}

variable "DST_CHAIN_TRANSFER_RECEIVER" {
  description = "DST_CHAIN_TRANSFER_RECEIVER"
  type        = string
}

variable "CROSS_CHAIN_TRANSFER_INFO_LIST" {
  description = "CROSS_CHAIN_TRANSFER_INFO_LIST"
  type = list(object({
    channel = string
    token   = string
  }))
}

variable "ACTIVE_IBC_ANCHOR_ID_LIST" {
  description = "ACTIVE_IBC_ANCHOR_ID_LIST"
  type        = list(string)
}
