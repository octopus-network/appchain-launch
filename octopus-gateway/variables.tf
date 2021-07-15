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
