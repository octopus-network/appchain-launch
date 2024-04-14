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
    name      = "runes-oracle-secret"
    namespace = data.kubernetes_namespace.default.metadata.0.name
  }
  data = {
    "identity.pem" = var.identity_pem
  }
}

resource "kubernetes_config_map" "default" {
  metadata {
    name      = "runes-oracle-config-map"
    namespace = data.kubernetes_namespace.default.metadata.0.name
  }
  data = {
    INDEXER_URL         = var.INDEXER_URL
    IC_GATEWAY          = var.IC_GATEWAY
    CUSTOMS_CANISTER_ID = var.CUSTOMS_CANISTER_ID
    PEM_PATH            = var.PEM_PATH
  }
}

resource "kubernetes_deployment" "default" {
  metadata {
    name = "runes-oracle"
    labels = {
      app = "runes-oracle"
    }
    namespace = data.kubernetes_namespace.default.metadata.0.name
  }
  spec {
    replicas = var.runes_oracle.replicas
    selector {
      match_labels = {
        app = "runes-oracle"
      }
    }
    template {
      metadata {
        labels = {
          app = "runes-oracle"
        }
      }
      spec {
        container {
          name    = "runes-oracle"
          image   = var.runes_oracle.image
          command = ["runes_oracle"]
          env_from {
            config_map_ref {
              name = kubernetes_config_map.default.metadata.0.name
            }
          }
          volume_mount {
            name       = "runes-oracle-secret-volume"
            mount_path = var.PEM_PATH
            sub_path   = "identity.pem"
          }
          resources {
            limits = {
              cpu    = var.runes_oracle.resources.cpu_limits
              memory = var.runes_oracle.resources.memory_limits
            }
            requests = {
              cpu    = var.runes_oracle.resources.cpu_requests
              memory = var.runes_oracle.resources.memory_requests
            }
          }
        }
        volume {
          name = "runes-oracle-secret-volume"
          secret {
            secret_name = kubernetes_secret.default.metadata.0.name
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
