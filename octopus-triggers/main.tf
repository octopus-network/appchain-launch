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
    name        = "triggers-ksa"
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
    name      = "triggers-secret"
    namespace = data.kubernetes_namespace.default.metadata.0.name
  }
  data = {
    PGUSER     = var.database.username
    PGPASSWORD = var.database.password
    PGDATABASE = var.database.database

    APPCHAIN_ORACLE_PHRASE      = var.APPCHAIN_ORACLE_PHRASE
    REGISTRY_ADMIN_NEAR_ACCOUNT = var.REGISTRY_ADMIN_NEAR_ACCOUNT
  }
}

resource "kubernetes_config_map" "default" {
  metadata {
    name      = "triggers-config-map"
    namespace = data.kubernetes_namespace.default.metadata.0.name
  }
  data = {
    LISTENING_PORT = var.triggers.listening_port

    GCE_PROXY_INSTANCES = var.gce_proxy_instances
    PGHOST              = var.database.host
    PGPORT              = var.database.port

    APPCHAIN_SETTINGS = var.APPCHAIN_SETTINGS
    CONTRACTS         = var.CONTRACTS
    NEAR_SETTINGS     = var.NEAR_SETTINGS

    NETWORK_ID                   = var.contract.network_id
    COUNTING_INTERVAL_IN_SECONDS = var.contract.counting_interval
    PRICE_NEEDED_APPCHAIN_IDS    = var.contract.price_needed_appchain_ids
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
          name  = "triggers-app"
          image = var.triggers.image
          command = var.triggers.app_cmd == null ? null : split(" ", var.triggers.app_cmd)
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
              cpu    = var.triggers_resources.cpu_requests
              memory = var.triggers_resources.memory_requests
            }
          }
        }
        container {
          name  = "triggers-server"
          image = var.triggers.image
          command = var.triggers.server_cmd == null ? null : split(" ", var.triggers.server_cmd)
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
              cpu    = var.triggers_resources.cpu_requests
              memory = var.triggers_resources.memory_requests
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
      name      = "triggers-backendconfig"
      namespace = data.kubernetes_namespace.default.metadata.0.name
    }
    spec = {
      healthCheck = {
        type        = "HTTP"
        requestPath = "/healthz"
        port        = var.triggers.listening_port
      }
    }
  }
}

resource "kubernetes_service" "default" {
  metadata {
    name      = "triggers"
    namespace = data.kubernetes_namespace.default.metadata.0.name
    labels = {
      app  = "triggers"
    }
    annotations = {
      "cloud.google.com/neg" = "{\"ingress\": true}"
      "cloud.google.com/backend-config" = "{\"default\": \"triggers-backendconfig\"}"
    }
  }
  spec {
    type = "NodePort"
    selector = {
      app  = "triggers"
    }
    port {
      port        = var.triggers.listening_port
      target_port = var.triggers.listening_port
      protocol    = "TCP"
    }
  }
}

resource "google_compute_global_address" "default" {
  name = "triggers-global-address"
}

data "google_dns_managed_zone" "default" {
  name = var.dns_zone
}

resource "google_dns_record_set" "a" {
  name         = "triggers.${data.google_dns_managed_zone.default.dns_name}"
  managed_zone = data.google_dns_managed_zone.default.name
  type         = "A"
  ttl          = 300
  rrdatas = [google_compute_global_address.default.address]
}

resource "google_dns_record_set" "caa" {
  name         = "triggers.${data.google_dns_managed_zone.default.dns_name}"
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
      name      = "triggers-managed-certificate"
      namespace = data.kubernetes_namespace.default.metadata.0.name
    }
    spec = {
      domains = [trimsuffix(google_dns_record_set.a.name, ".")]
    }
  }
}

resource "kubernetes_ingress_v1" "default" {
  metadata {
    name        = "triggers-ingress"
    namespace   = data.kubernetes_namespace.default.metadata.0.name
    annotations = {
      "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.default.name
      "networking.gke.io/managed-certificates"      = "triggers-managed-certificate"
      "kubernetes.io/ingress.class"                 = "gce"
    }
  }
  spec {
    default_backend {
      service {
        name = kubernetes_service.default.metadata.0.name
        port {
          number = var.triggers.listening_port
        }
      }
    }
  }
}