
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

# cloud sql proxy
variable "gce_proxy_image" {
  description = "description"
  type        = string
}

variable "gce_proxy_instances" {
  description = "description"
  type        = string
}

variable "gcp_service_account" {
  description = "description"
  type        = string
}

# bridge tx fetcher
variable "bridge_image" {
  description = "Bridge Image"
  type        = string
}

variable "near_rpc_endpoint" {
  description = "NEAR_RPC_ENDPOINT"
  type        = string
}

variable "near_indexer_db_config" {
  description = "NEAR_INDEXER_DB_CONFIG"
  type        = object({
    host     = string
    port     = number
    database = string
    user     = string
    password = string
  })
}

variable "data_db_config" {
  description = "DATA_DB_CONFIG"
  type        = object({
    host     = string
    port     = number
    database = string
    user     = string
    password = string
  })
}

variable "appchain_settings" {
  description = "APPCHAIN_SETTINGS"
  type        = list(object({
      appchainName     = string
      anchorContractId = string
      subqlEndpoint    = string
  })) 
}
