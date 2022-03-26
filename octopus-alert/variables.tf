
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