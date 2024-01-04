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

variable "resources" {
  description = "Resources"
  type = object({
    cpu_requests    = string
    cpu_limits      = string
    memory_requests = string
    memory_limits   = string
  })
  default = {
    cpu_limits      = "250m"
    cpu_requests    = "250m"
    memory_limits   = "512Mi"
    memory_requests = "512Mi"
  }
}
