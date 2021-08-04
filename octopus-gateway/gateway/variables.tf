variable "gateway" {
  type = object({
    api_domains     = list(string)
    api_image       = string
    messenger_image = string
    stat_image      = string
  })
}

variable "chains" {
  description = ""
  type        = list(object({
    name    = string
    service = string
  }))
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

variable "pubsub" {
  description = ""
  type = object({
    topic        = string
    subscription = string
    # service account key file
    sa_key       = string
  })
}