variable "relayer_image" {
  type        = string
  description = "description"
}

variable "relayer_private_key" {
  description = "description"
  type        = string
}

variable "relay_contract_id" {
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
  default     = "500m"
}

variable "cpu_limits" {
  description = ""
  type        = string
  default     = "500m"
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
  default     = "10Gi"
}