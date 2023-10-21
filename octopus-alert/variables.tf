
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

variable "cosmos_balance_config" {
  description = "COSMOS_BALANCE_CONFIG"
  type        = object({
    cronSchedule = string
    rpc          = string
    denom        = string
    watchList    = list(map(number))
  })
}

variable "dfinity_balance_config" {
  description = "DFINITY_BALANCE_CONFIG"
  type        = object({
    cronSchedule = string
    host         = string
    canisterId   = string
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

# public variable set
variable "APPCHAIN_IDS" {
  description = "APPCHAIN_IDS"
  type        = list(string)
}

variable "GLOBAL_SETTINGS" {
  description = "GLOBAL_SETTINGS"
  type = object({
    mmrExpireBlocks                 = number
    syncHistoryBlocks               = number
    appchain2NearExpireBlocks       = number
    near2AppchainExpireMinutes      = number
    eraSwitchExpireMinutes          = number
    eraActionCompleteExpiredMinutes = number
  })
}

variable "APPCHAIN_SETTINGS" {
  description = "APPCHAIN_SETTINGS"
  type = map(object({
    appchainId    = string
    subqlEndpoint = string
    wsRpcEndpoint = string
  }))
}
variable "CONTRACTS" {
  description = "CONTRACTS"
  type = object({
    registryContract   = string
    daoContractId      = string
    octTokenContractId = string
  })
}

variable "NEAR_SETTINGS" {
  description = "NEAR_SETTINGS"
  type = object({
    nearEnv             = string
    nearNodeUrl         = string
    archivalNearNodeUrl = string
    walletUrl           = string
    helperUrl           = string
  })
}