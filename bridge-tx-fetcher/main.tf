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
    LISTENING_PORT    = var.listening_port
    NEAR_ENV = var.near_env
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
            limits = {
              cpu    = var.gce_proxy_resources.cpu_limits
              memory = var.gce_proxy_resources.memory_limits
            }
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
          resources {
            limits = {
              cpu    = var.bridge_resources.cpu_limits
              memory = var.bridge_resources.memory_limits
            }
            requests = {
              cpu    = var.bridge_resources.cpu_requests
              memory = var.bridge_resources.memory_requests
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

resource "kubernetes_manifest" "default" {
  manifest = {
    apiVersion = "cloud.google.com/v1"
    kind       = "BackendConfig"
    metadata   = {
      name      = "bridge-tx-fetcher-backendconfig"
      namespace = var.namespace
    }
    spec = {
      healthCheck = {
        type        = "HTTP"
        requestPath = "/healthz"
        port        = var.listening_port
      }
    }
  }
}

resource "kubernetes_service" "default" {
  metadata {
    name      = "bridge-tx-fetcher"
    namespace = var.namespace
    labels = {
      app  = "bridge-tx-fetcher"
    }
    annotations = {
      "cloud.google.com/neg" = "{\"ingress\": true}"
      "cloud.google.com/backend-config" = "{\"default\": \"bridge-tx-fetcher-backendconfig\"}"
    }
  }
  spec {
    type = "NodePort"
    selector = {
      app  = "bridge-tx-fetcher"
    }
    port {
      port        = var.listening_port
      target_port = var.listening_port
      protocol    = "TCP"
    }
  }
}

resource "google_compute_global_address" "default" {
  name = "bridge-tx-fetcher-global-address"
}

data "google_dns_managed_zone" "default" {
  name = var.dns_zone
}

resource "google_dns_record_set" "a" {
  name         = "bridge-tx-fetcher.${data.google_dns_managed_zone.default.dns_name}"
  managed_zone = data.google_dns_managed_zone.default.name
  type         = "A"
  ttl          = 300
  rrdatas = [google_compute_global_address.default.address]
}

resource "google_dns_record_set" "caa" {
  name         = "bridge-tx-fetcher.${data.google_dns_managed_zone.default.dns_name}"
  managed_zone = data.google_dns_managed_zone.default.name
  type         = "CAA"
  ttl          = 300
  rrdatas = ["0 issue \"pki.goog\""]
}

resource "kubernetes_manifest" "certificate" {
  manifest = {
    apiVersion = "networking.gke.io/v1"
    kind       = "ManagedCertificate"
    metadata   = {
      name      = "bridge-tx-fetcher-managed-certificate"
      namespace = var.namespace
    }
    spec = {
      domains = [trimsuffix(google_dns_record_set.a.name, ".")]
    }
  }
}

resource "kubernetes_ingress_v1" "default" {
  metadata {
    name        = "bridge-tx-fetcher-ingress"
    namespace   = var.namespace
    annotations = {
      "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.default.name
      "networking.gke.io/managed-certificates"      = "bridge-tx-fetcher-managed-certificate"
      "kubernetes.io/ingress.class"                 = "gce"
    }
  }
  spec {
    default_backend {
      service {
        name = kubernetes_service.default.metadata.0.name
        port {
          number = var.listening_port
        }
      }
    }
  }
}
