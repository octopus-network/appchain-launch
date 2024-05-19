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

resource "kubernetes_config_map" "default" {
  metadata {
    name      = "triggers-config-map"
    namespace = data.kubernetes_namespace.default.metadata.0.name
  }
  data = {
    BTC_ENV                     = var.BTC_ENV
    BTC_CUSTOMS_DEPOSIT_ADDRESS = var.BTC_CUSTOMS_DEPOSIT_ADDRESS
    CANISTERS                   = var.CANISTERS
  }
}

resource "kubernetes_deployment" "default" {
  metadata {
    name = "triggers"
    labels = {
      app = "triggers"
    }
    namespace = data.kubernetes_namespace.default.metadata.0.name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "triggers"
      }
    }
    template {
      metadata {
        labels = {
          app = "triggers"
        }
      }
      spec {
        container {
          name  = "triggers"
          image = var.triggers.image
          env_from {
            config_map_ref {
              name = kubernetes_config_map.default.metadata.0.name
            }
          }
          resources {
            requests = {
              cpu    = var.triggers.resources.cpu_requests
              memory = var.triggers.resources.memory_requests
            }
          }
        }
      }
    }
  }
  lifecycle {
    ignore_changes = [
      spec[0].template[0].spec[0].container[0].resources,
    ]
  }
}
