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

# redis
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

# etcd
variable "etcd" {
  description = "Etcd Configuration"
  type = object({
    hosts    = string
    username = string
    password = string
  })
}

# kafka
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
