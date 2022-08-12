resource "kubernetes_secret" "default" {
  metadata {
    name      = "octopus-gateway-api-secret"
    namespace = var.namespace
  }
  data = {
    "config.yaml" = templatefile("${path.module}/template/config.yaml.tftpl", var.postgresql)
  }
}

resource "kubernetes_deployment" "default" {
  metadata {
    name      = "octopus-gateway-api"
    namespace = var.namespace
    labels = {
      name = "octopus-gateway-api"
      app  = "octopus-gateway"
    }
  }
  spec {
    replicas = var.gateway_api.replicas
    selector {
      match_labels = {
        name = "octopus-gateway-api"
        app  = "octopus-gateway"
      }
    }
    template {
      metadata {
        labels = {
          name = "octopus-gateway-api"
          app  = "octopus-gateway"
        }
      }
      spec {
        container {
          name  = "api"
          image = var.gateway_api.api_image
          port {
            container_port = 80
          }
          volume_mount {
            name       = "api-secret-volume"
            mount_path = "/octopus-gateway/config.yaml"
            sub_path   = "config.yaml"
            read_only  = true
          }
          resources {
            requests = {
              cpu    = var.gateway_api.resources.api_cpu_requests
              memory = var.gateway_api.resources.api_memory_requests
            }
          }
        }
        container {
          name  = "proxy"
          image = var.gateway_api.proxy_image
          command = ["/cloud_sql_proxy", "-instances=${var.gateway_api.proxy_instance}"]
          security_context {
            run_as_non_root = true
          }
          resources {
            requests = {
              cpu    = var.gateway_api.resources.proxy_cpu_requests
              memory = var.gateway_api.resources.proxy_memory_requests
            }
          }
        }
        volume {
          name = "api-secret-volume"
          secret {
            secret_name = kubernetes_secret.default.metadata.0.name
          }
        }
        service_account_name = var.service_account
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

resource "kubernetes_service" "default" {
  metadata {
    name      = "octopus-gateway-api"
    namespace = var.namespace
    labels = {
      name = "octopus-gateway-api"
      app  = "octopus-gateway"
    }
    annotations = {
      "cloud.google.com/neg" = "{\"ingress\": true}"
    }
  }
  spec {
    type = "ClusterIP"
    selector = {
      name = "octopus-gateway-api"
      app  = "octopus-gateway"
    }
    port {
      port        = 80
      target_port = 80
      protocol    = "TCP"
    }
  }
}
