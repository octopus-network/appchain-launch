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
variable "chains" {
  description = "Chains Configuration"
  type = map(object({
    chainspec = string
    bootnodes = list(string)
    image     = string
    command   = string
    replicas  = number
  }))
}

#
variable "etcd" {
  description = "Etcd Configuration"
  type = object({
    hosts    = string
    username = string
    password = string
  })
}
