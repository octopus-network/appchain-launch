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
    BALANCE_CONFIG         = jsonencode(var.balance_config)
    COSMOS_BALANCE_CONFIG  = jsonencode(var.cosmos_balance_config)
    DFINITY_BALANCE_CONFIG = jsonencode(var.dfinity_balance_config)
    REGISTRY_ADDRESS       = jsonencode(var.registry_address)
    OCT_TOKEN_ADDRESS      = jsonencode(var.oct_token_address)
    LPOS_CONFIG            = jsonencode(var.lpos_config)
    BRIDGE_CONFIG          = jsonencode(var.bridge_config)
    ERA_CONFIG             = jsonencode(var.era_config)
    MMR_CONFIG             = jsonencode(var.mmr_config)
    UNWITHDRAWN_CONFIG     = jsonencode(var.unwithdrawn_config)
    NEAR_ERRORS            = jsonencode(var.near_errors)
    APPCHAIN_SETTINGS      = jsonencode(var.APPCHAIN_SETTINGS)
    CONTRACTS              = jsonencode(var.CONTRACTS)
    NEAR_SETTINGS          = jsonencode(var.NEAR_SETTINGS)
    APPCHAIN_IDS           = jsonencode(var.APPCHAIN_IDS)
    GLOBAL_SETTINGS        = jsonencode(var.GLOBAL_SETTINGS)
  }
}

resource "kubernetes_secret" "default" {
  metadata {
    name      = "octopus-alert-secret"
    namespace = var.namespace
  }
  data = {
    PAGERDUTY_TOKEN	= var.pagerduty_token
    PAGERDUTY_SERVICE	= var.pagerduty_service
    EMAIL_ENDPOINT	= var.email_endpoint
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
          command = ["yarn"]
          args    = ["balance-alert"]
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
          command = ["yarn"]
          args    = ["bridge-alert"]
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
          command = ["yarn"]
          args    = ["era-alert"]
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
          command = ["yarn"]
          args    = ["lpos-alert"]
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
          command = ["yarn"]
          args    = ["mmr-alert"]
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
          command = ["yarn"]
          args    = ["near-errors-alert"]
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
          command = ["yarn"]
          args    = ["unwithdrawn-alert"]
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
        init_container {
          name              = "init-db"
          image             = "busybox"
          command           = ["touch", "/tmp/email-service.db"]
          resources {
            limits = {
              cpu    = "100m"
              memory = "100Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "100Mi"
            }
          }
          volume_mount {
            name       = "octopus-alert-volume"
            mount_path = "/tmp"
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name      = "octopus-alert-volume"
        namespace = var.namespace
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
  lifecycle {
    ignore_changes = [
      spec[0].template[0].spec[0].container[0].resources,
      spec[0].template[0].spec[0].container[1].resources,
      spec[0].template[0].spec[0].container[2].resources,
      spec[0].template[0].spec[0].container[3].resources,
      spec[0].template[0].spec[0].container[4].resources,
      spec[0].template[0].spec[0].container[5].resources,
      spec[0].template[0].spec[0].container[6].resources
    ]
  }
}
