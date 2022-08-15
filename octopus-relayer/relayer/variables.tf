variable "relayer_image" {
  type        = string
  description = "description"
}

variable "relayer_id" {
  description = "description"
  type        = string
}

variable "relayer_private_key" {
  description = "description"
  type        = string
}

variable "anchor_contract_id" {
  description = "description"
  type        = string
}

variable "appchain_id" {
  description = "description"
  type        = string
}

variable "appchain_endpoint" {
  description = "description"
  type        = string
}

variable "start_block_height" {
  description = "description"
  type        = number
}

variable "update_state_min_interval" {
  description = "description"
  type        = number
}

variable "node_env" {
  description = "description"
  type        = string
}

variable "near_node_url" {
  description = "description"
  type        = string
}

variable "near_wallet_url" {
  description = "description"
  type        = string
}

variable "near_helper_url" {
  description = "description"
  type        = string
}

variable "replicas" {
  description = ""
  type        = number
  default     = 1
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
  default     = "512Mi"
}

variable "memory_limits" {
  description = ""
  type        = string
  default     = "512Mi"
}

variable "volume_type" {
  description = ""
  type        = string
  default     = "standard-rwo"
}

variable "volume_size" {
  description = ""
  type        = string
  default     = "1Gi"
}

variable "namespace" {
  description = "Namespace"
  type        = string
  default     = "default" # devnet / testnet / mainnet
}
