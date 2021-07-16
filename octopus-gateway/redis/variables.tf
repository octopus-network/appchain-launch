variable "create" {
  description = ""
  type        = bool
  default     = true
}

variable "region" {
  description = "Region"
  type        = string
}

variable "name" {
  description = ""
  type        = string
  default     = "octopus-redis"
}

variable "tier" {
  description = ""
  type        = string
  default     = "BASIC" # STANDARD_HA
}

variable "redis_version" {
  description = ""
  type        = string
  default     = "REDIS_5_0"
}

variable "memory_size" {
  description = ""
  type        = number
  default     = 1
}

variable "auth_enabled" {
  description = ""
  type        = bool
  default     = true
}

variable "tls_enabled" {
  description = ""
  type        = bool
  default     = true
}