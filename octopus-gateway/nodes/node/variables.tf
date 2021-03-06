
variable "chain_name" {
  description = ""
  type        = string
}

variable "chain_spec" {
  description = ""
  type        = string
}

variable "base_image" {
  description = "Pull base image from Docker Hub or a different registry"
  type        = string
}

variable "start_cmd" {
  description = ""
  type        = string
  default     = "node-template"
}

variable "replicas" {
  description = ""
  type        = number
  default     = 1
}

variable "telemetry_url" {
  description = ""
  type        = string
}

variable "rust_log" {
  description = ""
  type        = string
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
  default     = "10Gi"
}

variable "namespace" {
  description = "Namespace"
  type        = string
  default     = "default" # devnet / testnet / mainnet
}
