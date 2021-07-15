
variable "chain_name" {
  description = ""
  type        = string
}

variable "chainspec_url" {
  description = "Specifies which chain specification to use"
  type        = string
}

variable "bootnodes" {
  description = "Bootnodes"
  type        = list(string)
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
