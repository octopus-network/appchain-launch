variable "namespace" {
  description = "namespace"
  type        = string
}

variable "appchain_id" {
  description = "description"
  type        = string
}

variable "appchain_endpoint" {
  description = "description"
  type        = string
}

variable "gce_proxy_image" {
  description = "description"
  type        = string
}

variable "gce_proxy_instances" {
  description = "description"
  type        = string
}

variable "subql_node_image" {
  description = "description"
  type        = string
}

variable "subql_query_image" {
  description = "description"
  type        = string
}

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