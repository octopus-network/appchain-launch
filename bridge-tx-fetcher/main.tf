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

resource "kubernetes_service_account" "default" {
  metadata {
    name = "bridge-tx-fetcher-ksa"
    namespace = var.namespace
    annotations = {
      "iam.gke.io/gcp-service-account" = var.gcp_service_account
    }
  }
}

data "google_service_account" "default" {
  account_id = var.gcp_service_account
}

resource "google_service_account_iam_member" "default" {
  service_account_id = data.google_service_account.default.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project}.svc.id.goog[${var.namespace}/${kubernetes_service_account.default.metadata.0.name}]"
}

resource "kubernetes_secret" "default" {
  metadata {
    name      = "bridge-tx-fetcher-secret"
    namespace = var.namespace
  }
  data = {
    DATA_DB_CONFIG         = jsonencode(var.data_db_config)
    NEAR_INDEXER_DB_CONFIG = jsonencode(var.near_indexer_db_config)
  }
}

resource "kubernetes_config_map" "default" {
  metadata {
    name      = "bridge-tx-fetcher-config-map"
    namespace = var.namespace
  }
  data = {
    NEAR_RPC_ENDPOINT = var.near_rpc_endpoint
    APPCHAIN_SETTINGS = jsonencode(var.appchain_settings)
  }
}

resource "kubernetes_deployment" "default" {
  metadata {
    name = "bridge-tx-fetcher"
    labels = {
      app   = "bridge-tx-fetcher"
    }
    namespace = var.namespace
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app   = "bridge-tx-fetcher"
      }
    }
    template {
      metadata {
        labels = {
          app   = "bridge-tx-fetcher"
        }
      }
      spec {
        container {
          name    = "cloud-sql-proxy"
          image   = var.gce_proxy_image
          command = ["/cloud_sql_proxy", "-instances=${var.gce_proxy_instances}"]
          resources {
            requests = {
              cpu    = "1"
              memory = "2Gi"
            }
          }
          security_context {
            run_as_non_root = true
          }
        }
        container {
          name  = "bridge-tx-fetcher"
          image = var.bridge_image
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
        }
        service_account_name = kubernetes_service_account.default.metadata.0.name
      }
    }
  }
}