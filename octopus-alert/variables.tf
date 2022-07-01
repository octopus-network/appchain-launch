
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

variable "resources" {
  description = "Resources Configuration"
  type = object({
    cpu_requests    = string
    cpu_limits      = string
    memory_requests = string
    memory_limits   = string
    volume_type     = string
    volume_size     = string
  })
  default = {
    cpu_requests    = "100m"
    cpu_limits      = "200m"
    memory_requests = "300Mi"
    memory_limits   = "600Mi"
    volume_type     = "standard-rwo"
    volume_size     = "1Gi"
  }
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

variable "pagerduty_service" {
  description = "Pagerduty Service"
  type        = string
}

variable "email_endpoint" {
  description = "EMAIL_ENDPOINT"
  type        = string
}

variable "registry_address" {
  description = "REGISTRY_ADDRESS"
  type        = string
}

variable "oct_token_address" {
  description = "OCT_TOKEN_ADDRESS"
  type        = string
}

# alert env
variable "balance_config" {
  description = "BALANCE_CONFIG"
  type        = object({
    cronSchedule = string
    watchList    = list(map(number))
  })
}

variable "lpos_config" {
  description = "LPOS_CONFIG"
  type        = object({
    cronSchedule = string
  })
  default     = {
    cronSchedule = "0 */2 * * *"
  }
}

variable "bridge_config" {
  description = "BRIDGE_CONFIG"
  type        = object({
    cronSchedule = string
  })
  default     = {
    cronSchedule = "0 */2 * * *"
  }
}

variable "era_config" {
  description = "ERA_CONFIG"
  type        = object({
    cronSchedule = string
  })
  default     = {
    cronSchedule = "0 */2 * * *"
  }
}

variable "mmr_config" {
  description = "MMR_CONFIG"
  type        = object({
    cronSchedule = string
  })
  default     = {
    cronSchedule = "0 */2 * * *"
  }
}

variable "unwithdrawn_config" {
  description = "UNWITHDRAWN_CONFIG"
  type        = object({
    cronSchedule = string
  })
  default     = {
    cronSchedule = "0 */2 * * *"
  }
}

variable "near_errors" {
  description = "NEAR_ERRORS"
  type        = object({
    cronSchedule         = string
    contractList         = list(string)
    listenHistoryMinutes = number
    indexerSqlSetting    = object({
      host     = string
      port     = number
      database = string
      username = string
      password = string
    })
    largeAmount = number
  })
}

variable "appchain_settings" {
  description = "APPCHAIN_SETTINGS"
  type        = list(object({
      appchainName               = string
      anchorContractId           = string
      appchainEndpoint           = string
      mmrExpireBlocks            = number
      syncHistoryBlocks          = number
      appchain2NearExpireBlocks  = number
      near2AppchainExpireMinutes = number

      eraSwitchExpireMinutes          = number
      eraPayoutExpireMinutes          = number
      eraActionCompleteExpiredMinutes = number
  })) 
}
