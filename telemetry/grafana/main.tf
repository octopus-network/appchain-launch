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
    name      = "grafana-secret"
    namespace = var.namespace
  }
  data = {
    admin-user     = var.admin.user
    admin-password = var.admin.password
  }
}

resource "kubernetes_config_map" "default" {
  metadata {
    name      = "grafana-config-map"
    namespace = var.namespace
  }

  data = {
    "grafana.ini" = <<EOT
      [log]
      mode = "console"
      [paths]
      data = "/var/lib/grafana/"
      logs = "/var/log/grafana"
      plugins = "/var/lib/grafana/plugins"
      provisioning = "/etc/grafana/provisioning"
      [server]
      domain = "chart-example.local"
    EOT
  }
}

resource "kubernetes_persistent_volume_claim" "default" {
  metadata {
    name      = "grafana-persistent-volume-claim"
    namespace = var.namespace
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "standard-rwo"
    resources {
      requests = {
        storage = "20Gi"
      }
    }
  }
  wait_until_bound = false
}

resource "kubernetes_deployment" "grafana" {
  metadata {
    name      = "grafana"
    namespace = var.namespace
    labels = {
      app = "grafana"
    }
  }

  spec {
    replicas               = 1
    revision_history_limit = 10
    selector {
      match_labels = {
        app = "grafana"
      }
    }
    template {
      metadata {
        labels = {
          app = "grafana"
        }
      }
      spec {
        init_container {
          name  = "init-chown-data"
          image = "busybox:1.31.1"
          security_context {
            capabilities {
              add = ["CHOWN"]
            }
            run_as_non_root = false
            run_as_user     = 0
            seccomp_profile {
              type = "RuntimeDefault"
            }
          }
          command = ["chown", "-R", "472:472", "/var/lib/grafana"]
          volume_mount {
            name       = "grafana-data-volume"
            mount_path = "/var/lib/grafana"
          }
        }
        container {
          name  = "grafana"
          image = "grafana/grafana:10.2.2"
          port {
            name          = "grafana"
            container_port = 3000
            protocol      = "TCP"
          }
          port {
            name          = "gossip-tcp"
            container_port = 9094
            protocol      = "TCP"
          }
          port {
            name          = "gossip-udp"
            container_port = 9094
            protocol      = "UDP"
          }
          env {
            name = "POD_IP"
            value_from {
              field_ref {
                field_path = "status.podIP"
              }
            }
          }
          env {
            name = "GF_SECURITY_ADMIN_USER"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.default.metadata.0.name
                key  = "admin-user"
              }
            }
          }
          env {
            name = "GF_SECURITY_ADMIN_PASSWORD"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.default.metadata.0.name
                key  = "admin-password"
              }
            }
          }
          env {
            name  = "GF_PATHS_DATA"
            value = "/var/lib/grafana/"
          }
          env {
            name  = "GF_PATHS_LOGS"
            value = "/var/log/grafana"
          }
          env {
            name  = "GF_PATHS_PLUGINS"
            value = "/var/lib/grafana/plugins"
          }
          env {
            name  = "GF_PATHS_PROVISIONING"
            value = "/etc/grafana/provisioning"
          }
          volume_mount {
            name       = "grafana-config-volume"
            mount_path = "/etc/grafana/grafana.ini"
            sub_path   = "grafana.ini"
          }

          volume_mount {
            name       = "grafana-data-volume"
            mount_path = "/var/lib/grafana"
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
          liveness_probe {
            http_get {
              path   = "/api/health"
              port   = 3000
            }
            initial_delay_seconds = 60
            timeout_seconds      = 30
          }
          readiness_probe {
            http_get {
              path = "/api/health"
              port = 3000
            }
          }
        }
        volume {
          name = "grafana-config-volume"
          config_map {
            name = kubernetes_config_map.default.metadata.0.name
          }
        }
        volume {
          name = "grafana-data-volume"
          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.default.metadata.0.name
          }
        }
        security_context {
          fs_group      = 472
          run_as_group  = 472
          run_as_non_root = true
          run_as_user   = 472
        }
      }
    }
  }
}

resource "kubernetes_manifest" "default" {
  manifest = {
    apiVersion = "cloud.google.com/v1"
    kind       = "BackendConfig"
    metadata = {
      name      = "grafana-backendconfig"
      namespace = var.namespace
    }
    spec = {
      healthCheck = {
        type        = "HTTP"
        requestPath = "/api/health"
        port        = 3000
      }
    }
  }
}

resource "kubernetes_service" "default" {
  metadata {
    name      = "grafana"
    namespace = var.namespace
    labels = {
      app  = "grafana"
    }
    annotations = {
      "cloud.google.com/neg"            = "{\"ingress\": true}"
      "cloud.google.com/backend-config" = "{\"default\": \"grafana-backendconfig\"}"
    }
  }
  spec {
    type = "NodePort"
    selector = {
      app  = "grafana"
    }
    port {
      port        = 3000
      target_port = 3000
      protocol    = "TCP"
      name        = "http"
    }
  }
}

resource "kubernetes_ingress_v1" "default" {
  metadata {
    name      = "grafana-ingress"
    namespace = var.namespace
    annotations = {
      "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.default.name
      "networking.gke.io/managed-certificates"      = "grafana-managed-certificate"
      "kubernetes.io/ingress.class"                 = "gce"
      "kubernetes.io/ingress.allow-http"            = "true"
    }
  }
  spec {
    default_backend {
      service {
        name = "grafana"
        port {
          number = 3000
        }
      }
    }
  }
}

# ip & dns record & certificate
resource "google_compute_global_address" "default" {
  name = "grafana-global-address"
}

data "google_dns_managed_zone" "default" {
  name = var.dns_zone
}

resource "google_dns_record_set" "a" {
  name         = "grafana.${data.google_dns_managed_zone.default.dns_name}"
  managed_zone = data.google_dns_managed_zone.default.name
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.default.address]
}

resource "google_dns_record_set" "caa" {
  name         = "grafana.${data.google_dns_managed_zone.default.dns_name}"
  managed_zone = data.google_dns_managed_zone.default.name
  type         = "CAA"
  ttl          = 300
  rrdatas      = ["0 issue \"pki.goog\""]
}

resource "kubernetes_manifest" "certificate" {
  manifest = {
    apiVersion = "networking.gke.io/v1"
    kind       = "ManagedCertificate"
    metadata = {
      name      = "grafana-managed-certificate"
      namespace = var.namespace
    }
    spec = {
      domains = [trimsuffix(google_dns_record_set.a.name, ".")]
    }
  }
}