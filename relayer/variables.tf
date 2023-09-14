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

variable "rust_log" {
  description = "RUST_LOG"
  type        = string
  default     = ""
}

variable "cpu_requests" {
  description = ""
  type        = string
  default     = "250m"
}

variable "cpu_limits" {
  description = ""
  type        = string
  default     = "250m"
}

variable "memory_requests" {
  description = ""
  type        = string
  default     = "1000Mi"
}

variable "memory_limits" {
  description = ""
  type        = string
  default     = "1000Mi"
}

variable "volume_type" {
  description = ""
  type        = string
  default     = "standard-rwo"
}

variable "volume_size" {
  description = ""
  type        = string
  default     = "20Gi"
}

# hermes relayers
variable "relayers" {
  description = "Hermes image"
  type = map(object({
    image         = string
    chain_id_1    = string
    chain_id_2    = string
  }))
}

variable "relayer_keys" {
  description = "Hermes used keys"
  type = map(object({
    ic_credential = string
    credential_1  = string
    credential_2  = string
  }))
  sensitive = true
}