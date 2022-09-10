
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

variable "near_env" {
  description = "NEAR_ENV"
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
      httpRpcEndpoint  = string
  })) 
}
