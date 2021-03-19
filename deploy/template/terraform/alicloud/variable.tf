
variable "access_key" {
  type = string
}

variable "secret_key" {
  type = string
}

variable "region" {
  type    = string
  default = "cn-hangzhou"
}

variable "vpc_name" {
  type = string
}

variable "vswitch_name" {
  type = string
}

variable "security_group_name" {
  type = string
}

variable "instance_name" {
  type = string
}

variable "instance_type" {
    type = string
    default = "ecs.g6.xlarge"
}

variable "key_name" {
  type = string
}

variable "public_key" {
  type = string
}
