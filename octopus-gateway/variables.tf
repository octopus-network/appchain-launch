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

# 
variable "gateway" {
  description = "Gateway Configuration"
  type = object({
    api_domains     = list(string)
    api_image       = string
    messenger_image = string
    stat_image      = string
  })
}

# 
variable "chains" {
  description = "Chains Configuration"
  type = map(object({
    # name      = string
    chainspec = string
    bootnodes = list(string)
    image     = string
    command   = string
    replicas  = number
  }))
}

#
variable "redis" {
  description = "Redis Configuration"
  type = object({
    create       = bool
    name         = string
    region       = string
    tier         = string
    version      = string
    memory_size  = number
    auth_enabled = bool
    tls_enabled  = bool
  })
}

# pubsub
variable "pubsub" {
  description = ""
  type = object({
    topic        = string
    subscription = string
    # service account key file
    sa_key       = string
  })
}
