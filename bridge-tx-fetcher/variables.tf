
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

variable "dns_zone" {
  description = "DNS Zone"
  type        = string
}

# cloud sql proxy
variable "gce_proxy_image" {
  description = "GCE Proxy Image"
  type        = string
}

variable "gce_proxy_instances" {
  description = "GCE Proxy Instances"
  type        = string
}

variable "gcp_service_account" {
  description = "GCP Service Account"
  type        = string
}

variable "gce_proxy_resources" {
  description = "GCE Proxy Resources Configuration"
  type = object({
    cpu_requests    = string
    cpu_limits      = string
    memory_requests = string
    memory_limits   = string
  })
  default = {
    cpu_requests    = "100m"
    cpu_limits      = "500m"
    memory_requests = "200Mi"
    memory_limits   = "800Mi"
  }
}

# bridge tx fetcher
variable "bridge_image" {
  description = "Bridge Image"
  type        = string
}

variable "bridge_resources" {
  description = "Bridge Resources Configuration"
  type = object({
    cpu_requests    = string
    cpu_limits      = string
    memory_requests = string
    memory_limits   = string
  })
  default = {
    cpu_requests    = "100m"
    cpu_limits      = "500m"
    memory_requests = "200Mi"
    memory_limits   = "800Mi"
  }
}

variable "listening_port" {
  description = "LISTENING_PORT"
  type        = number
  default     = 3000
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

# public variable set
variable "APPCHAIN_SETTINGS" {
  description = "APPCHAIN_SETTINGS"
  type = map(object({
    appchainId    = string
    subqlEndpoint = string
    wsRpcEndpoint = string
  }))
}

variable "APPCHAIN_IDS" {
  description = "APPCHAIN_IDS"
  type        = list(string)
}

variable "CONTRACTS" {
  description = "CONTRACTS"
  type = object({
    registryContract   = string
    daoContractId      = string
    octTokenContractId = string
  })
}

variable "NEAR_SETTINGS" {
  description = "NEAR_SETTINGS"
  type = object({
    nearEnv             = string
    nearNodeUrl         = string
    archivalNearNodeUrl = string
    walletUrl           = string
    helperUrl           = string
  })
}