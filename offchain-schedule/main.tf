provider "google" {
  project = var.project
  region  = var.region
}

data "google_client_config" "default" {
}

data "google_container_cluster" "default" {
  name     = var.cluster
  location = var.region
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.default.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.default.master_auth[0].cluster_ca_certificate)
}

data "kubernetes_namespace" "default" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret" "default" {
  metadata {
    name      = "offchain-schedule-secret"
    namespace = data.kubernetes_namespace.default.metadata.0.name
  }
  data = {
    SCHEDULE_SIGNER_SECRET_KEY = var.SCHEDULE_SIGNER_SECRET_KEY
  }
}

resource "kubernetes_config_map" "default" {
  metadata {
    name      = "offchain-schedule-config-map"
    namespace = data.kubernetes_namespace.default.metadata.0.name
  }
  data = {
    NEAR_ENV                        = var.NEAR_ENV
    NEAR_CLI_TESTNET_RPC_SERVER_URL = var.NEAR_CLI_TESTNET_RPC_SERVER_URL
    NEAR_CLI_MAINNET_RPC_SERVER_URL = var.NEAR_CLI_MAINNET_RPC_SERVER_URL
    SCHEDULE_SIGNER                 = var.SCHEDULE_SIGNER
    LPOS_MARKET_CONTRACT            = var.LPOS_MARKET_CONTRACT
    APPCHAIN_REGISTRY_CONTRACT      = var.APPCHAIN_REGISTRY_CONTRACT
    DST_CHAIN_TRANSFER_RECEIVER     = var.DST_CHAIN_TRANSFER_RECEIVER
    CROSS_CHAIN_TRANSFER_INFO_LIST  = jsonencode(var.CROSS_CHAIN_TRANSFER_INFO_LIST)
    ACTIVE_IBC_ANCHOR_ID_LIST       = jsonencode(var.ACTIVE_IBC_ANCHOR_ID_LIST)
  }
}

resource "kubernetes_deployment" "default" {
  metadata {
    name = "offchain-schedule"
    labels = {
      app = "offchain-schedule"
    }
    namespace = data.kubernetes_namespace.default.metadata.0.name
  }
  spec {
    replicas = var.offchain_schedule.replicas
    selector {
      match_labels = {
        app = "offchain-schedule"
      }
    }
    template {
      metadata {
        labels = {
          app = "offchain-schedule"
        }
      }
      spec {
        container {
          name  = "offchain-schedule"
          image = var.offchain_schedule.image
          env_from {
            secret_ref {
              name = kubernetes_secret.default.metadata.0.name
            }
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.default.metadata.0.name
            }
          }
          resources {
            limits = {
              cpu    = var.offchain_schedule.resources.cpu_limits
              memory = var.offchain_schedule.resources.memory_limits
            }
            requests = {
              cpu    = var.offchain_schedule.resources.cpu_requests
              memory = var.offchain_schedule.resources.memory_requests
            }
          }
        }
      }
    }
  }
  lifecycle {
    ignore_changes = [
      spec[0].template[0].spec[0].container[0].resources
    ]
  }
}
