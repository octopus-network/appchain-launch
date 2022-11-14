variable "triggers" {
  description = "Octopus Triggers Configuration"
  type = object({
    image          = string
    app_cmd        = optional(string)
    server_cmd     = optional(string)
    listening_port = string
  })
}

variable "triggers_resources" {
  description = "Octopus Score Counter Resources"
  type        = object({
    cpu_requests    = string
    memory_requests = string
  })
  default = {
    cpu_requests    = "150m"
    memory_requests = "256Mi"
  }
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

variable "gce_proxy_resources" {
  description = "Octopus GCE Proxy Resources"
  type        = object({
    cpu_requests      = string
    memory_requests   = string
  })
  default = {
    cpu_requests    = "100m"
    memory_requests = "256Mi"
  }
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
    token_contract_id = string
    account_id        = string
    private_key       = string
    counting_interval = number
    dao_contract_id   = string
    # update-prices service
    price_needed_appchains       = string
    appchain_price_setter_phrase = string
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

variable "dns_zone" {
  description = "DNS Zone"
  type        = string
}
