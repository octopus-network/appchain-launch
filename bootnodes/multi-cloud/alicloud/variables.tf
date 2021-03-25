
variable "access_key" {
  description = "Access key"
  type        = string
}

variable "secret_key" {
  description = "Secret key"
  type        = string
}

variable "region" {
  description = "Region"
  type        = string
  default     = "ap-northeast-1"
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "ecs.g6.large"
}

variable "instance_count" {
  description = "Instance count"
  type        = number
  default     = 1
}

variable "public_key_file" {
  description = ""
  type        = string
}

variable "module_depends_on" {
  description = "Any to have module depend on"
  type        = any
  default     = []
}