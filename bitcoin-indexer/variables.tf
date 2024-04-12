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
  default     = "default" # testnet / mainnet
}

variable "dns_zone" {
  description = "DNS zone"
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

# chain
variable "bitcoind" {
  description = "bitcoind node"
  type = object({
    image = string
    chain = string # main, test, signet, regtest
    rpc = object({
      user     = string
      password = string
    })
    resources = object({
      cpu_requests    = string
      cpu_limits      = string
      memory_requests = string
      memory_limits   = string
      volume_type     = string
      volume_size     = string
    })
  })
}

variable "ord" {
  description = "ord index"
  type = object({
    image = string
    chain = string # mainnet, testnet, signet, regtest
    bitcoin = object({
      rpc_user = string
      rpc_pass = string
    })
    resources = object({
      cpu_requests    = string
      cpu_limits      = string
      memory_requests = string
      memory_limits   = string
      volume_type     = string
      volume_size     = string
    })
  })
}

variable "sql_proxy" {
  description = "sql proxy"
  type = object({
    database  = string
    resources = object({
      cpu_requests    = string
      cpu_limits      = string
      memory_requests = string
      memory_limits   = string
    })
  })
}
