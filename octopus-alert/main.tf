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

resource "kubernetes_config_map" "default" {
  metadata {
    name      = "octopus-alert-config-map"
    namespace = var.namespace
  }
  data = {
    NEAR_ENV          = var.near.env
    NEAR_NODE_URL     = var.near.node_url
    NEAR_WALLET_URL   = var.near.wallet_url
    NEAR_HELPER_URL   = var.near.helper_url
    BALANCE_CONFIG    = jsonencode(var.balance_config)
    LPOS_CONFIG       = jsonencode(var.lpos_config)
    BRIDGE_CONFIG     = jsonencode(var.bridge_config)
    ERA_CONFIG        = jsonencode(var.era_config)
    MMR_CONFIG        = jsonencode(var.mmr_config)
    NEAR_ERRORS       = jsonencode(var.near_errors)
    APPCHAIN_SETTINGS = jsonencode(var.appchain_settings)
  }
}

resource "kubernetes_secret" "default" {
  metadata {
    name      = "octopus-alert-secret"
    namespace = var.namespace
  }
  data = {
    PAGERDUTY_TOKEN = var.pagerduty_token
  }
}

resource "kubernetes_deployment" "default" {
  metadata {
    name = "octopus-alert"
    labels = {
      app = "octopus-alert"
    }
    namespace = var.namespace
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "octopus-alert"
      }
    }
    template {
      metadata {
        labels = {
          app = "octopus-alert"
        }
      }
      spec {
        container {
          name    = "balance-alert"
          image   = var.alert_image
          command = ["node"]
          args    = ["./dist/monitors/balance/index.js"]
          env_from {
            config_map_ref {
              name = kubernetes_config_map.default.metadata.0.name
            }
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.default.metadata.0.name
            }
          }
        }
        container {
          name    = "bridge-alert"
          image   = var.alert_image
          command = ["node"]
          args    = ["./dist/monitors/bridge/index.js"]
          env_from {
            config_map_ref {
              name = kubernetes_config_map.default.metadata.0.name
            }
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.default.metadata.0.name
            }
          }
        }
        container {
          name    = "era-alert"
          image   = var.alert_image
          command = ["node"]
          args    = ["./dist/monitors/era/index.js"]
          env_from {
            config_map_ref {
              name = kubernetes_config_map.default.metadata.0.name
            }
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.default.metadata.0.name
            }
          }
        }
        container {
          name    = "lpos-alert"
          image   = var.alert_image
          command = ["node"]
          args    = ["./dist/monitors/lpos/index.js"]
          env_from {
            config_map_ref {
              name = kubernetes_config_map.default.metadata.0.name
            }
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.default.metadata.0.name
            }
          }
        }
        container {
          name    = "mmr-alert"
          image   = var.alert_image
          command = ["node"]
          args    = ["./dist/monitors/mmr/index.js"]
          env_from {
            config_map_ref {
              name = kubernetes_config_map.default.metadata.0.name
            }
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.default.metadata.0.name
            }
          }
        }
      }
    }
  }
}