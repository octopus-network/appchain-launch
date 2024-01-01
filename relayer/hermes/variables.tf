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

variable "image" {
  description = "description"
  type        = string
}

variable "ic_credential" {
  description = "IC Credential"
  type        = string
  sensitive   = true
}

variable "chain_id_1" {
  description = "Chain ID 1"
  type        = string
}

variable "credential_1" {
  description = "Credential 1"
  type        = string
  sensitive   = true
}

variable "chain_id_2" {
  description = "Chain ID 2"
  type        = string
}

variable "credential_2" {
  description = "Credential 2"
  type        = string
  sensitive   = true
}

variable "viewstate_near_endpoint" {
  description = "ViewState NEAR Endpoint"
  type        = string
}

variable "ic_endpoint" {
  description = "IC Endpoint"
  type        = string
}

variable "canister_id" {
  description = "Canister ID"
  type        = string
}

variable "canister_pem" {
  description = "Canister PEM"
  type        = string
}
