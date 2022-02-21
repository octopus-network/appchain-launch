
# router
resource "kubernetes_config_map" "default" {
  metadata {
    name      = "octopus-gateway-router-configmap"
    namespace = var.namespace
  }
  data = {
    GATEWAY_API_ROUTE_URL = "http://octopus-gateway-api/route"
  }
}

resource "kubernetes_secret" "default" {
  metadata {
    name      = "octopus-gateway-router-secret"
    namespace = var.namespace
  }
  data = {
    "fluentd.conf" = templatefile("${path.module}/template/fluentd.conf.tftpl", var.kafka)
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
          env {
            name = "GATEWAY_API_ROUTE_URL"
            value_from {
              config_map_key_ref {
                name = kubernetes_config_map.default.metadata.0.name
                key  = "GATEWAY_API_ROUTE_URL"
              }
            }
          }
          volume_mount {
            name       = "router-log-volume"
            mount_path = "/octopus-gateway/logs"
          }
        }
        # container {
        #   name  = "fluentd"
        #   image = var.gateway_router.fluentd_image
        #   volume_mount {
        #     name       = "router-log-volume"
        #     mount_path = "/var/log/gateway"
        #   }
        #   volume_mount {
        #     name       = "router-secret-volume"
        #     mount_path = "/fluentd/etc/fluent.conf"
        #     sub_path   = "fluentd.conf"
        #   }
        # }
        volume {
          name = "router-log-volume"
          empty_dir {
          }
        }
        volume {
          name = "router-secret-volume"
          secret {
            secret_name = kubernetes_secret.default.metadata.0.name
          }
        }
      }
    }
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

resource "kubernetes_ingress" "default" {
  metadata {
    name        = "octopus-gateway-ingress"
    namespace   = var.namespace
    annotations = {
      "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.default.name
      "networking.gke.io/managed-certificates"      = "octopus-gateway-managed-certificate"
      "kubernetes.io/ingress.class"                 = "gce"
    }
  }
  spec {
    backend {
      service_name = kubernetes_service.default.metadata.0.name
      service_port = 80
    }
  }
}
