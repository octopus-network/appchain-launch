
variable "cloud_vendor" {
  description = "Cloud Vendor (Alicoud, AWS, Azure, Google Cloud)"
  type        = string
  default     = ""
}

variable "access_key" {
  description = "Access key"
  type        = string
}

variable "secret_key" {
  description = "Secret key"
  type        = string
}

variable "region" {
  description = "Region"
  type        = string
  default     = "ap-northeast-1"
}


variable "bootnodes" {
  description = "The number of bootnodes"
  type        = number
  default     = 1
}

variable "chain_spec" {
  description = "Specifies which chain specification to use"
  type        = string
  default     = ""
}

variable "p2p_peer_ids" {
  description = "Subtrate node identity file (node libp2p key)"
  type        = list(string)
  default     = []
}

variable "p2p_port" {
  description = "Specifies the port that your node will listen for p2p traffic on"
  type        = string
  default     = 30333
}

variable "rpc_port" {
  description = "Specifies the port that your node will listen for incoming RPC traffic on"
  type        = string
  default     = 9933
}

variable "ws_port" {
  description = "Specifies the port that your node will listen for incoming WebSocket traffic on"
  type        = string
  default     = 9944
}

variable "base_image" {
  description = "Pull base image from  Docker Hub or a different registry"
  type        = string
}

variable "start_cmd" {
  description = "No need to set if ENTRYPOINT is used, otherwise fill in the start command"
  type        = string
  default     = ""
}

variable "wasm_url" {
  description = ""
  type        = string
}

variable "wasm_checksum" {
  description = ""
  type        = string
}

variable "inventory_template" {
  description = "Ansible inventory template file"
  type        = string
  default     = ""
}

variable "user" {
  description = ""
  type        = string
  default     = "root"
}
