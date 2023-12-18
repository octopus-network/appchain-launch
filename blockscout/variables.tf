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

variable "dns_zone" {
  description = "DNS zone"
  type        = string
}

# blockscout
variable "chains" {
  description = "Blockscout Configuration"
  type = list(object({
    chain = string
    frontend = object({
      image    = string
      replicas = number
      envs     = map(string)
      resources = object({
        cpu_requests    = string
        cpu_limits      = string
        memory_requests = string
        memory_limits   = string
      })
    })
    backend = object({
      image    = string
      replicas = number
      envs     = map(string)
      resources = object({
        cpu_requests    = string
        cpu_limits      = string
        memory_requests = string
        memory_limits   = string
      })
    })
  }))
}

variable "verifier" {
  description = "Blockscout Configuration"
  type = object({
    image    = string
    replicas = number
    envs     = map(string)
    resources = object({
      cpu_requests    = string
      cpu_limits      = string
      memory_requests = string
      memory_limits   = string
    })
  })
}
