
variable "chain_name" {
  description = ""
  type        = string
}

variable "dirs" {
  description = ""
  type        = list(string)
}

variable "keys" {
  description = ""
  type        = list(string)
  default     = ["babe.json", "gran.json", "imon.json", "beef.json", "octo.json"]
}

variable "module_depends_on" {
  description = "Any to have module depend on"
  type        = any
  default     = []
}

variable "namespace" {
  description = "Namespace"
  type        = string
  default     = "default" # devnet / testnet / mainnet
}
