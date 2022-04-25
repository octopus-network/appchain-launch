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
    NEAR_ENV          	= var.near.env
    NEAR_NODE_URL     	= var.near.node_url
    NEAR_WALLET_URL   	= var.near.wallet_url
    NEAR_HELPER_URL   	= var.near.helper_url
    BALANCE_CONFIG    	= jsonencode(var.balance_config)
    LPOS_CONFIG       	= jsonencode(var.lpos_config)
    BRIDGE_CONFIG     	= jsonencode(var.bridge_config)
    ERA_CONFIG        	= jsonencode(var.era_config)
    MMR_CONFIG        	= jsonencode(var.mmr_config)
    UNWITHDRAWN_CONFIG	= jsonencode(var.unwithdrawn_config)
    NEAR_ERRORS       	= jsonencode(var.near_errors)
    APPCHAIN_SETTINGS 	= jsonencode(var.appchain_settings)
  }
}

resource "kubernetes_secret" "default" {
  metadata {
    name      = "octopus-alert-secret"
    namespace = var.namespace
  }
  data = {
    PAGERDUTY_TOKEN = var.pagerduty_token
    EMAIL_ENDPOINT  = var.email_endpoint
  }
}

resource "kubernetes_stateful_set" "default" {
  metadata {
    name = "octopus-alert"
    labels = {
      app = "octopus-alert"
    }
    namespace = var.namespace
  }
  spec {
    service_name = "octopus-alert"
    replicas     = 1
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
          resources {
            limits = {
              cpu    = var.resources.cpu_limits
              memory = var.resources.memory_limits
            }
            requests = {
              cpu    = var.resources.cpu_requests
              memory = var.resources.memory_requests
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
          resources {
            limits = {
              cpu    = var.resources.cpu_limits
              memory = var.resources.memory_limits
            }
            requests = {
              cpu    = var.resources.cpu_requests
              memory = var.resources.memory_requests
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
          resources {
            limits = {
              cpu    = var.resources.cpu_limits
              memory = var.resources.memory_limits
            }
            requests = {
              cpu    = var.resources.cpu_requests
              memory = var.resources.memory_requests
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
          resources {
            limits = {
              cpu    = var.resources.cpu_limits
              memory = var.resources.memory_limits
            }
            requests = {
              cpu    = var.resources.cpu_requests
              memory = var.resources.memory_requests
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
          resources {
            limits = {
              cpu    = var.resources.cpu_limits
              memory = var.resources.memory_limits
            }
            requests = {
              cpu    = var.resources.cpu_requests
              memory = var.resources.memory_requests
            }
          }
        }
        container {
          name    = "near-errors-alert"
          image   = var.alert_image
          command = ["node"]
          args    = ["./dist/monitors/near-errors/index.js"]
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
          resources {
            limits = {
              cpu    = var.resources.cpu_limits
              memory = var.resources.memory_limits
            }
            requests = {
              cpu    = var.resources.cpu_requests
              memory = var.resources.memory_requests
            }
          }
        }
        container {
          name    = "unwithdrawn-alert"
          image   = var.alert_image
          command = ["node"]
          args    = ["./dist/monitors/unwithdrawn/index.js"]
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
          resources {
            limits = {
              cpu    = var.resources.cpu_limits
              memory = var.resources.memory_limits
            }
            requests = {
              cpu    = var.resources.cpu_requests
              memory = var.resources.memory_requests
            }
          }
          volume_mount {
            name       = "octopus-alert-volume"
            mount_path = "/usr/src/app/email-service.db"
            sub_path   = "email-service.db"
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "octopus-alert-volume"
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = var.resources.volume_type
        resources {
          requests = {
            storage = var.resources.volume_size
          }
        }
      }
    }
  }
}
