
variable "chainspec_url" {
  description = "Specifies which chain specification to use"
  type        = string
  default     = ""
}

variable "chainspec_checksum" {
  description = "Specifies which chain specification to use"
  type        = string
  default     = ""
}

variable "bootnodes" {
  description = "Specify a list of bootnodes"
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

variable "keys_octoup" {
  description = "Keys generated by octokey. https://github.com/octopus-network/octokey"
  type        = string
  default     = ""
}

# 
variable "cloud_vendor" {
  description = "Cloud Vendor (Alicoud, AWS, Azure, Google Cloud)"
  type        = string
  default     = ""
}

variable "access_key" {
  description = "Access key"
  type        = string
  default     = ""
}

variable "secret_key" {
  description = "Secret key"
  type        = string
  default     = ""
}

variable "project" {
  description = "ID of the gcp project"
  type        = string
  default     = ""
}

variable "region" {
  description = "Region"
  type        = string
  default     = "ap-northeast-1"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["ap-northeast-1a"]
}

variable "vpc_cidr" {
  description = "The cidr block used to launch a new vpc"
  type        = string
  default     = "172.16.0.0/16"
}

variable "public_cidrs" {
  description = "List of cidr blocks used to launch several new vswitches"
  type        = list(string)
  default     = ["172.16.1.0/24"]
}

variable "private_cidrs" {
  description = "List of cidr blocks used to launch several new vswitches"
  type        = list(string)
  default     = []
}

# https://aws.amazon.com/cn/ec2/instance-types/
variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.micro"
}

variable "instance_count" {
  description = "Instance count"
  type        = number
  default     = 1
}

variable "volume_type" {
  description = ""
  type        = string
  default     = "gp2"
}

variable "volume_size" {
  description = ""
  type        = number
  default     = 80
}

variable "kms_key_spec" {
  description = ""
  type        = string
  default     = "ECC_SECG_P256K1"
}

variable "kms_key_alias" {
  description = ""
  type        = string
  default     = "alias/octopus-key-alias"
}

variable "create_lb" {
  description = "Whether to create load balancer"
  type        = bool
  default     = false 
}

variable "create_dns_record" {
  description = "Whether to create DNS record"
  type        = bool
  default     = false 
}

variable "domain_name" {
  description = "Use an existing domain name"
  type        = string
  default     = ""
}

variable "record_name" {
  description = ""
  type        = string
  default     = "" 
}

variable "certificate" {
  description = ""
  type        = string
  default     = ""
}

variable "node_exporter_enabled" {
  description = "Enable node exporter"
  type        = bool
  default     = true
}

variable "node_exporter_binary_url" {
  description = "Node exporter url"
  type        = string
  default     = "https://github.com/prometheus/node_exporter/releases/download/v1.1.2/node_exporter-1.1.2.linux-amd64.tar.gz"
}

variable "node_exporter_binary_checksum" {
  description = "SHA256 hash of node exporter binary"
  type        = string
  default     = "sha256:8c1f6a317457a658e0ae68ad710f6b4098db2cad10204649b51e3c043aa3e70d"
}

variable "node_exporter_port" {
  description = ""
  type        = string
  default     = 9100
}

variable "node_exporter_user" {
  description = "User for node exporter"
  type        = string
  default     = "prometheus"
}

variable "node_exporter_password" {
  description = "Password for node exporter"
  type        = string
  default     = "node_exporter"
}

variable "user" {
  description = ""
  type        = string
  default     = "root"
}
