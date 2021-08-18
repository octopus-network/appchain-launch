variable "appchain_id" {
  description = "description"
  type        = string
}

variable "uploader_config" {
  description = "description"
  type        = string
  validation {
    condition     = fileexists(var.uploader_config)
    error_message = "The uploader config json must exist."
  }
}

variable "uploader_secret" {
  description = "description"
  type        = string
  validation {
    condition     = fileexists(var.uploader_secret)
    error_message = "The uploader secret json must exist."
  }
}

variable "validator_config" {
  description = "description"
  type        = string
  validation {
    condition     = fileexists(var.validator_config)
    error_message = "The validator config json must exist."
  }
}

variable "validator_secret" {
  description = "description"
  type        = string
  validation {
    condition     = fileexists(var.validator_secret)
    error_message = "The validator secret json must exist."
  }
}

variable "kyve_image" {
  type        = string
  description = "description"
}
