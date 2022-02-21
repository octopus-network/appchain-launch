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
        }
        container {
          name  = "proxy"
          image = var.gateway_api.proxy_image
          command = ["/cloud_sql_proxy", "-instances=${var.gateway_api.proxy_instance}"]
          security_context {
            run_as_non_root = true
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
