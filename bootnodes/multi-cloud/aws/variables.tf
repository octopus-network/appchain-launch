
variable "create" {
  description = "Whether to create AWS"
  type        = bool
  default     = true
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

variable "public_key_file" {
  description = "SSH public key file path"
  type        = string
}

variable "create_lb_53_acm" {
  description = "Whether to create load balancer, route53 record, certificate"
  type        = bool
  default     = false 
}

variable "domain_name" {
  description = "Use an existing domain name"
  type        = string
  default     = "" 
}

variable "route53_record_name" {
  description = ""
  type        = string
  default     = "" 
}

variable "id" {
  description = ""
  type        = string
}

variable "module_depends_on" {
  description = "Any to have module depend on"
  type        = any
  default     = []
}
