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

resource "kubernetes_service_account" "default" {
  metadata {
    name        = "score-counter-ksa"
    namespace   = data.kubernetes_namespace.default.metadata.0.name
    annotations = {
      "iam.gke.io/gcp-service-account" = var.service_account
    }
  }
}

data "google_service_account" "default" {
  account_id = var.service_account
}

resource "google_service_account_iam_member" "default" {
  service_account_id = data.google_service_account.default.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project}.svc.id.goog[${data.kubernetes_namespace.default.metadata.0.name}/${kubernetes_service_account.default.metadata.0.name}]"
}

resource "kubernetes_secret" "default" {
  metadata {
    name      = "score-counter-secret"
    namespace = data.kubernetes_namespace.default.metadata.0.name
  }
  data = {
    PGUSER     = var.database.username
    PGPASSWORD = var.database.password
    PGDATABASE = var.database.database

    ADMIN_PRIVATE_KEY = var.contract.private_key
  }
}

resource "kubernetes_config_map" "default" {
  metadata {
    name      = "score-counter-config-map"
    namespace = data.kubernetes_namespace.default.metadata.0.name
  }
  data = {
    GCE_PROXY_INSTANCES = var.gce_proxy_instances
    PGHOST              = var.database.host
    PGPORT              = var.database.port

    NEAR_NODE_URL   = var.near.node_url
    NEAR_WALLET_URL = var.near.wallet_url
    NEAR_HELPER_URL = var.near.helper_url

    NETWORK_ID                   = var.contract.network_id
    REGISTRY_CONTRACT_ID         = var.contract.contract_id
    TOKEN_CONTRACT_ID            = var.contract.token_contract_id
    ADMIN_ACCOUNT_ID             = var.contract.account_id
    COUNTING_INTERVAL_IN_SECONDS = var.contract.counting_interval
  }
}

resource "kubernetes_deployment" "default" {
  metadata {
    name = "score-counter"
    labels = {
      app = "score-counter"
    }
    namespace = data.kubernetes_namespace.default.metadata.0.name
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "score-counter"
      }
    }
    template {
      metadata {
        labels = {
          app = "score-counter"
        }
      }
      spec {
        container {
          name    = "cloud-sql-proxy"
          image   = var.gce_proxy_image
          command = ["/cloud_sql_proxy", "-instances=$(GCE_PROXY_INSTANCES)"]
          env {
            name = "GCE_PROXY_INSTANCES"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.default.metadata.0.name
                key  = "GCE_PROXY_INSTANCES"
              }
            }
          }
          resources {
            requests = {
              cpu    = var.gce_proxy_resources.cpu_requests
              memory = var.gce_proxy_resources.memory_requests
            }
          }
          security_context {
            run_as_non_root = true
          }
        }
        container {
          name  = "score-counter"
          image = var.score_counter_image
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
            requests = {
              cpu    = var.score_counter_resources.cpu_requests
              memory = var.score_counter_resources.memory_requests
            }
          }
        }
        service_account_name = kubernetes_service_account.default.metadata.0.name
      }
    }
  }
  lifecycle {
    ignore_changes = [
      spec[0].template[0].spec[0].container[0].resources,
      spec[0].template[0].spec[0].container[1].resources
    ]
  }
}
