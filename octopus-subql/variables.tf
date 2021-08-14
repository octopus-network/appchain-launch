variable "subql_domains" {
  description = "description"
  type        = list(string)
}

variable "subql" {
  description = "Subql Configuration"
  type = map(object({
    appchain_id         = string
    appchain_endpoint   = string
    gce_proxy_image     = string
    gce_proxy_instances = string
    subql_node_image    = string
    subql_query_image   = string
  }))
}

# postgresql
variable "database" {
  description = "DB Configuration"
  type = object({
    username = string
    password = string
    database = string
  })
}

variable "service_account" {
  description = "description"
  type        = string
}

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
