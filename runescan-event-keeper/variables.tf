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

# chain

variable "event_keeper" {
  description = "runescan event keeper"
  type = object({
    image = string
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
    image     = string
    instances = string
    database  = string
    resources = object({
      cpu_requests    = string
      cpu_limits      = string
      memory_requests = string
      memory_limits   = string
    })
  })
}
