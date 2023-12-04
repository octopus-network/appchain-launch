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

# ip & dns record & certificate
resource "google_compute_global_address" "default" {
  name = "blockscout-global-address"
}

data "google_dns_managed_zone" "default" {
  name = var.dns_zone
}

resource "google_dns_record_set" "a" {
  count        = length(var.chains)
  name         = "${var.chains[count.index].chain}.blockscout.${data.google_dns_managed_zone.default.dns_name}"
  managed_zone = data.google_dns_managed_zone.default.name
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.default.address]
}

resource "google_dns_record_set" "caa" {
  count        = length(var.chains)
  name         = "${var.chains[count.index].chain}.blockscout.${data.google_dns_managed_zone.default.dns_name}"
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
      name      = "blockscout-managed-certificate"
      namespace = var.namespace
    }
    spec = {
      domains = [for s in google_dns_record_set.a : trimsuffix(s.name, ".")]
    }
  }
}

# config_map & deployment & service & ingress
resource "kubernetes_config_map" "frontend" {
  count = length(var.chains)
  metadata {
    name      = "${var.chains[count.index].chain}-blockscout-frontend-config-map"
    namespace = var.namespace
  }
  data = var.chains[count.index].frontend.envs
}

resource "kubernetes_config_map" "backend" {
  count = length(var.chains)
  metadata {
    name      = "${var.chains[count.index].chain}-blockscout-backend-config-map"
    namespace = var.namespace
  }
  data = var.chains[count.index].backend.envs
}

resource "kubernetes_deployment" "frontend" {
  count = length(var.chains)
  metadata {
    name = "${var.chains[count.index].chain}-blockscout-frontend"
    labels = {
      app = "${var.chains[count.index].chain}-blockscout-frontend"
    }
    namespace = var.namespace
  }
  spec {
    replicas = var.chains[count.index].frontend.replicas
    selector {
      match_labels = {
        app = "${var.chains[count.index].chain}-blockscout-frontend"
      }
    }
    template {
      metadata {
        labels = {
          app = "${var.chains[count.index].chain}-blockscout-frontend"
        }
      }
      spec {
        container {
          name  = "blockscout-frontend"
          image = var.chains[count.index].frontend.image
          port {
            container_port = 3000
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.frontend[count.index].metadata.0.name
            }
          }
          resources {
            limits = {
              cpu    = var.chains[count.index].frontend.resources.cpu_limits
              memory = var.chains[count.index].frontend.resources.memory_limits
            }
            requests = {
              cpu    = var.chains[count.index].frontend.resources.cpu_requests
              memory = var.chains[count.index].frontend.resources.memory_requests
            }
          }
          readiness_probe {
            http_get {
              path = "/api/healthz"
              port = 3000
            }
            initial_delay_seconds = 60
            period_seconds        = 10
            timeout_seconds       = 3
          }
          liveness_probe {
            http_get {
              path = "/api/healthz"
              port = 3000
            }
            initial_delay_seconds = 100
            period_seconds        = 100
            timeout_seconds       = 30
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

resource "kubernetes_deployment" "backend" {
  count = length(var.chains)
  metadata {
    name = "${var.chains[count.index].chain}-blockscout-backend"
    labels = {
      app = "${var.chains[count.index].chain}-blockscout-backend"
    }
    namespace = var.namespace
  }
  spec {
    replicas = var.chains[count.index].backend.replicas
    selector {
      match_labels = {
        app = "${var.chains[count.index].chain}-blockscout-backend"
      }
    }
    template {
      metadata {
        labels = {
          app = "${var.chains[count.index].chain}-blockscout-backend"
        }
      }
      spec {
        init_container {
          name    = "init-migrations"
          image   = var.chains[count.index].backend.image
          command = ["/bin/sh"]
          args    = ["-c", "bin/blockscout eval \"Elixir.Explorer.ReleaseTasks.create_and_migrate()\""]
          env_from {
            config_map_ref {
              name = kubernetes_config_map.backend[count.index].metadata.0.name
            }
          }
        }
        container {
          name    = "octopus-backend"
          image   = var.chains[count.index].backend.image
          command = ["/bin/sh"]
          args    = ["-c", "bin/blockscout start"]
          port {
            container_port = 4000
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.backend[count.index].metadata.0.name
            }
          }
          resources {
            limits = {
              cpu    = var.chains[count.index].backend.resources.cpu_limits
              memory = var.chains[count.index].backend.resources.memory_limits
            }
            requests = {
              cpu    = var.chains[count.index].backend.resources.cpu_requests
              memory = var.chains[count.index].backend.resources.memory_requests
            }
          }
          readiness_probe {
            http_get {
              path = "/api/v1/health/readiness"
              port = 4000
            }
            initial_delay_seconds = 60
            period_seconds        = 10
            timeout_seconds       = 3
          }
          liveness_probe {
            http_get {
              path = "/api/v1/health/readiness"
              port = 4000
            }
            initial_delay_seconds = 100
            period_seconds        = 100
            timeout_seconds       = 30
          }
        }
        termination_grace_period_seconds = 300
      }
    }
  }
  lifecycle {
    ignore_changes = [
      spec[0].template[0].spec[0].container[0].resources
    ]
  }
}

resource "kubernetes_manifest" "frontend" {
  manifest = {
    apiVersion = "cloud.google.com/v1"
    kind       = "BackendConfig"
    metadata = {
      name      = "blockscout-frontend-backendconfig"
      namespace = var.namespace
    }
    spec = {
      healthCheck = {
        type        = "HTTP"
        requestPath = "/api/healthz"
        port        = 3000
      }
    }
  }
}

resource "kubernetes_service" "frontend" {
  count = length(var.chains)
  metadata {
    name      = "${var.chains[count.index].chain}-blockscout-frontend"
    namespace = var.namespace
    labels = {
      app  = "${var.chains[count.index].chain}-blockscout-frontend"
    }
    annotations = {
      "cloud.google.com/neg"            = "{\"ingress\": true}"
      "cloud.google.com/backend-config" = "{\"default\": \"blockscout-frontend-backendconfig\"}"
    }
  }
  spec {
    type = "NodePort"
    selector = {
      app = "${var.chains[count.index].chain}-blockscout-frontend"
    }
    port {
      port        = 3000
      target_port = 3000
      protocol    = "TCP"
      name        = "http"
    }
  }
}

resource "kubernetes_manifest" "backend" {
  manifest = {
    apiVersion = "cloud.google.com/v1"
    kind       = "BackendConfig"
    metadata = {
      name      = "blockscout-backend-backendconfig"
      namespace = var.namespace
    }
    spec = {
      healthCheck = {
        type        = "HTTP"
        requestPath = "/api/v1/health/readiness"
        port        = 4000
      }
    }
  }
}

resource "kubernetes_service" "backend" {
  count = length(var.chains)
  metadata {
    name      = "${var.chains[count.index].chain}-blockscout-backend"
    namespace = var.namespace
    labels = {
      app  = "${var.chains[count.index].chain}-blockscout-backend"
    }
    annotations = {
      "cloud.google.com/neg"            = "{\"ingress\": true}"
      "cloud.google.com/backend-config" = "{\"default\": \"blockscout-backend-backendconfig\"}"
    }
  }
  spec {
    type = "NodePort"
    selector = {
      app  = "${var.chains[count.index].chain}-blockscout-backend"
    }
    port {
      port        = 4000
      target_port = 4000
      protocol    = "TCP"
      name        = "http"
    }
  }
}

resource "kubernetes_ingress_v1" "default" {
  metadata {
    name      = "blockscout-ingress"
    namespace = var.namespace
    annotations = {
      "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.default.name
      "networking.gke.io/managed-certificates"      = "blockscout-managed-certificate"
      "kubernetes.io/ingress.class"                 = "gce"
      "kubernetes.io/ingress.allow-http"            = "true"
    }
  }
  spec {
    dynamic "rule" {
      for_each = var.chains
      content {
        host = trimsuffix("${rule.value.chain}.blockscout.${data.google_dns_managed_zone.default.dns_name}", ".")
        http {
          path {
            path = "/api"
            path_type = "Prefix"
            backend {
              service {
                name = "${rule.value.chain}-blockscout-backend"
                port {
                  number = 4000
                }
              }
            }
          }
          path {
            path = "/socket"
            path_type = "Prefix"
            backend {
              service {
                name = "${rule.value.chain}-blockscout-backend"
                port {
                  number = 4000
                }
              }
            }
          }
          path {
            path = "/sitemap.xml"
            path_type = "Prefix"
            backend {
              service {
                name = "${rule.value.chain}-blockscout-backend"
                port {
                  number = 4000
                }
              }
            }
          }
          path {
            path = "/auth/auth0"
            path_type = "Exact"
            backend {
              service {
                name = "${rule.value.chain}-blockscout-backend"
                port {
                  number = 4000
                }
              }
            }
          }
          path {
            path = "/auth/auth0/callback"
            path_type = "Exact"
            backend {
              service {
                name = "${rule.value.chain}-blockscout-backend"
                port {
                  number = 4000
                }
              }
            }
          }
          path {
            path = "/auth/logout"
            path_type = "Exact"
            backend {
              service {
                name = "${rule.value.chain}-blockscout-backend"
                port {
                  number = 4000
                }
              }
            }
          }
          path {
            path = "/*"
            backend {
              service {
                name = "${rule.value.chain}-blockscout-frontend"
                port {
                  number = 3000
                }
              }
            }
          }
        }
      }
    }
  }
}
