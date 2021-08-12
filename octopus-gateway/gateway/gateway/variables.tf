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

variable "etcd" {
  description = ""
  type = object({
    hosts    = string
    username = string
    password = string
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