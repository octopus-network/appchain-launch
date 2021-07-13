variable "project" {
  description = "Project"
  type        = string
  default     = "orbital-builder-316023"
}

variable "region" {
  description = "Region"
  type        = string
  default     = "asia-northeast1"
}

variable "cluster" {
  description = "Cluster"
  type        = string
  default     = "autopilot-cluster-1"
}

# redis
variable "redis_tier" {
  description = ""
  type        = string
  default     = "BASIC" # STANDARD_HA
}

variable "redis_version" {
  description = ""
  type        = string
  default     = "REDIS_5_0"
}

variable "redis_memory_size" {
  description = ""
  type        = number
  default     = 1
}

variable "redis_auth_enabled" {
  description = ""
  type        = bool
  default     = true
}

variable "redis_tls_enabled" {
  description = ""
  type        = bool
  default     = true
}