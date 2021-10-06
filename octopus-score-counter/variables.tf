variable "score_counter_image" {
  description = "Octopus Score Counter Image"
  type        = string
}

# postgresql
variable "database" {
  description = "DB Configuration"
  type = object({
    username = string
    password = string
    database = string
    host     = string
    port     = string
  })
}

variable "gce_proxy_image" {
  description = "GCE Proxy Image"
  type        = string
}

variable "gce_proxy_instances" {
  description = "GCE Proxy Instances"
  type        = string
}

variable "service_account" {
  description = "Google Service Account"
  type        = string
}

# near
variable "near" {
  description = "Near Configuration"
  type = object({
    node_url   = string
    wallet_url = string
    helper_url = string
  })
}

# contract
variable "contract" {
  description = "Contract Configuration"
  type = object({
    network_id        = string
    contract_id       = string
    account_id        = string
    private_key       = string
    counting_interval = number
  })
  sensitive = true
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
