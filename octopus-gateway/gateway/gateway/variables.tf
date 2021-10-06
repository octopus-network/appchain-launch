variable "gateway" {
  type = object({
    api_domains     = list(string)
    api_image       = string
    messenger_image = string
    stat_image      = string
  })
}

variable "redis" {
  description = ""
  type = object({
    host     = string
    port     = string
    password = string
    tls_cert = string
  })
}

variable "kafka" {
  description = ""
  type = object({
    hosts = string
    topic = string
    sasl = object({
      mechanisms = string
      username   = string
      password   = string
    })
  })
}

variable "project" {
  description = "Project"
  type        = string
}

variable "service_account" {
  description = "description"
  type        = string
}

variable "network_id" {
  description = "Network ID"
  type        = string
  default     = "testnet"
}