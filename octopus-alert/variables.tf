
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

variable "namespace" {
  description = "Namespace"
  type        = string
  default     = "default" # devnet / testnet / mainnet
}

variable "alert_image" {
  description = "Image"
  type        = string
}

# near
variable "near" {
  description = "Near Configuration"
  type = object({
    env        = string
    node_url   = string
    wallet_url = string
    helper_url = string
  })
}

variable "pagerduty_token" {
  description = "Pagerduty Token"
  type        = string
}