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


resource "kubernetes_secret" "default" {
  metadata {
    name      = "runescan-event-keeper-secret"
    namespace = var.namespace
  }
  data = {
    DATABASE_URL = var.sql_proxy.database
  }
}


resource "kubernetes_deployment" "default" {
  metadata {
    name      = "runescan-event-keeper"
    namespace = var.namespace
    labels = {
      app = "runescan-event-keeper"
    }
  }
  spec {
    replicas               = 1
    revision_history_limit = 5
    selector {
      match_labels = {
        app = "runescan-event-keeper"
      }
    }
    template {
      metadata {
        labels = {
          app = "runescan-event-keeper"
        }
      }
      spec {
        container {
          name    = "runescan-event-keeper"
          image   = var.event_keeper.image
          env_from {
            secret_ref {
              name = kubernetes_secret.default.metadata.0.name
            }
          }
          resources {
            limits = {
              cpu    = var.event_keeper.resources.cpu_limits
              memory = var.event_keeper.resources.memory_limits
            }
            requests = {
              cpu    = var.event_keeper.resources.cpu_requests
              memory = var.event_keeper.resources.memory_requests
            }
          }
        }
        container {
          name    = "cloud-sql-proxy"
          image   = var.sql_proxy.image
          command = ["/cloud_sql_proxy", "-instances=${var.sql_proxy.instances}"]
          resources {
            limits = {
              cpu    = var.sql_proxy.resources.cpu_limits
              memory = var.sql_proxy.resources.memory_limits
            }
            requests = {
              cpu    = var.sql_proxy.resources.cpu_requests
              memory = var.sql_proxy.resources.memory_requests
            }
          }
          security_context {
            run_as_non_root = true
          }
        }
        service_account_name = "ord-ksa"
        termination_grace_period_seconds = 300
      }
    }
  }
  lifecycle {
    ignore_changes = [
      spec[0].template[0].spec[0].container[0].resources,
      spec[0].template[0].spec[0].container[1].resources,
    ]
  }
}

