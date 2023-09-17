
# router
resource "kubernetes_config_map" "default" {
  metadata {
    name      = "octopus-gateway-router-configmap"
    namespace = var.namespace
  }
  data = {
    GATEWAY_API_ROUTE_URL = "http://octopus-gateway-api/route"
    HITCH_ENTRYPOINT = file("${path.module}/hitch_entrypoint")
  }
}

resource "kubernetes_deployment" "default" {
  metadata {
    name      = "octopus-gateway-router"
    namespace = var.namespace
    labels = {
      name = "octopus-gateway-router"
      app  = "octopus-gateway"
    }
  }
  spec {
    replicas = var.gateway_router.replicas
    selector {
      match_labels = {
        name = "octopus-gateway-router"
        app  = "octopus-gateway"
      }
    }
    template {
      metadata {
        labels = {
          name = "octopus-gateway-router"
          app  = "octopus-gateway"
        }
      }
      spec {
        container {
          name  = "router"
          image = var.gateway_router.router_image
          port {
            container_port = 80
          }
          port {
            container_port = 81
          }
          env {
            name = "GATEWAY_API_ROUTE_URL"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.default.metadata.0.name
                key  = "GATEWAY_API_ROUTE_URL"
              }
            }
          }
          resources {
            requests = {
              cpu    = var.gateway_router.resources.cpu_requests
              memory = var.gateway_router.resources.memory_requests
            }
          }
        }
        container {
          name  = "hitch"
          image = "hitch:1.8.0"
          args = [
            "--backend=[127.0.0.1]:81",
            "--log-level=2",
            "--write-proxy-v2=off"
            # --tls-protos="TLSv1.2"
          ]
          port {
            container_port = 443
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
            name = "POD_NAME"
            value_from {
              field_ref {
                field_path = "metadata.name"
              }
            }
          }
          env {
            name = "POD_NAMESPACE"
            value_from {
              field_ref {
                field_path = "metadata.namespace"
              }
            }
          }
          volume_mount {
            name       = "octopus-gateway-router-config-volume"
            mount_path = "/usr/local/bin/docker-hitch-entrypoint"
            sub_path   = "HITCH_ENTRYPOINT"
          }
        }
        volume {
          name = "octopus-gateway-router-config-volume"
          config_map {
            name         = kubernetes_config_map.default.metadata.0.name
            default_mode = "0555"
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

resource "kubernetes_manifest" "default" {
  manifest = {
    apiVersion = "cloud.google.com/v1"
    kind       = "BackendConfig"
    metadata   = {
      name      = "octopus-gateway-router-backendconfig"
      namespace = var.namespace
    }
    spec = {
      healthCheck = {
        type        = "HTTP"
        requestPath = "/health"
        port        = 80
      }
      timeoutSec = 3600
      connectionDraining = {
        drainingTimeoutSec = 3600
      }
    }
  }
}

resource "kubernetes_service" "default" {
  metadata {
    name      = "octopus-gateway-router"
    namespace = var.namespace
    labels = {
      name = "octopus-gateway-router"
      app  = "octopus-gateway"
    }
    annotations = {
      "cloud.google.com/app-protocols": "{\"http2\": \"HTTP2\", \"http\": \"HTTP\"}"
      "cloud.google.com/neg" = "{\"ingress\": true}"
      "cloud.google.com/backend-config" = "{\"default\": \"octopus-gateway-router-backendconfig\"}"
    }
  }
  spec {
    type = "NodePort"
    selector = {
      name = "octopus-gateway-router"
      app  = "octopus-gateway"
    }
    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
      name        = "http"
    }
    port {
      port        = 443
      target_port = 443
      protocol    = "TCP"
      name        = "http2"
    }
  }
}

resource "google_compute_global_address" "default" {
  name = "octopus-gateway-global-address"
}

data "google_dns_managed_zone" "default" {
  name = var.gateway_router.dns_zone
}

resource "google_dns_record_set" "a" {
  name         = "gateway.${data.google_dns_managed_zone.default.dns_name}"
  managed_zone = data.google_dns_managed_zone.default.name
  type         = "A"
  ttl          = 300
  rrdatas = [google_compute_global_address.default.address]
}

resource "google_dns_record_set" "caa" {
  name         = "gateway.${data.google_dns_managed_zone.default.dns_name}"
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
      name      = "octopus-gateway-managed-certificate"
      namespace = var.namespace
    }
    spec = {
      domains = [trimsuffix(google_dns_record_set.a.name, ".")]
    }
  }
}

resource "kubernetes_ingress_v1" "default" {
  metadata {
    name        = "octopus-gateway-ingress"
    namespace   = var.namespace
    annotations = {
      "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.default.name
      "networking.gke.io/managed-certificates"      = "octopus-gateway-managed-certificate"
      "kubernetes.io/ingress.class"                 = "gce"
      "kubernetes.io/ingress.allow-http"            = "false"
    }
  }
  spec {
    default_backend {
      service {
        name = kubernetes_service.default.metadata.0.name
        port {
          number = 80
        }
      }
    }
    rule {
      http {
        dynamic "path" {
          for_each = var.gateway_router_gprc
          content {
            backend {
              service {
                name = kubernetes_service.default.metadata.0.name
                port {
                  number = 443
                }
              }
            }
            path = "/${path.value}/*"
          }
        }
      }
    }
  }
}
