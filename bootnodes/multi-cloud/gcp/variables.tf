variable "create" {
  description = "Whether to create GCP"
  type        = bool
  default     = true
}

variable "project" {
  description = "ID of the project"
  type        = string
}

variable "region" {
  description = "Region"
  type        = string
  default     = "asia-northeast1"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["asia-northeast1-a"]
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "e2-small"
}

variable "instance_count" {
  description = "Instance count"
  type        = number
  default     = 1
}

variable "volume_type" {
  description = ""
  type        = string
  default     = "pd-standard"
}

variable "volume_size" {
  description = ""
  type        = number
  default     = 10
}

variable "bind_eip" {
  description = ""
  type        = bool
  default     = true
}

variable "public_key_file" {
  description = "SSH public key file path"
  type        = string
}

variable "id" {
  description = ""
  type        = string
}