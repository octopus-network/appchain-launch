
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

variable "az" {
  description = "AWS availability zone"
  type        = string
  default     = "ap-northeast-1a"
}

variable "public_subnet_cidr" {
  description = "AWS availability zone"
  type        = string
  default     = "10.0.2.0/24"
}

# From https://cloud-images.ubuntu.com/locator/ec2/
variable "instance_ami" {
  description = "AWS ami image to use for core instances"
  type        = string
  default     = "ami-059b6d3840b03d6dd"
}

# https://aws.amazon.com/cn/ec2/instance-types/
variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.micro" # "m6g.large"
}

variable "instance_count" {
  description = "Instance count"
  type        = number
  default     = 1
}

variable "public_key_file" {
  description = ""
  type        = string
}

variable "module_depends_on" {
  description = "Any to have module depend on"
  type        = any
  default     = []
}
