resource "kubernetes_namespace" "default" {
  metadata {
    labels = {
      name = "gateway"
    }
    name = "gateway"
  }
}

# api
resource "kubernetes_config_map" "api" {
  metadata {
    name      = "api-config-map"
    namespace = "gateway"
  }
  data = {
    "dev.env.json" = file("${path.module}/dev.api.json")
  }
}

resource "kubernetes_deployment" "api" {
  metadata {
    name      = "api"
    labels = {
      app = "api"
    }
    namespace = "gateway"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "api"
      }
    }
    template {
      metadata {
        labels = {
          app = "api"
        }
      }
      spec {
        container {
          name  = "api"
          image = "asia-northeast1-docker.pkg.dev/orbital-builder-316023/docker-repository/octopus-gateway-api:0.0.1"
          port {
            container_port = 7003
          }
          volume_mount {
            name       = "api-config-volume"
            mount_path = "/app/api/config/env"
          }
          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
        }
        volume {
          name = "api-config-volume"
          config_map {
            name = kubernetes_config_map.api.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "api" {
  metadata {
    name     = "api"
    namespace = "gateway"
  }
  spec {
    type = "LoadBalancer"
    selector = {
      app = kubernetes_deployment.api.metadata.0.labels.app
    }
    session_affinity = "ClientIP"
    port {
      port        = 80
      target_port = 7003
      protocol    = "TCP"
    }
  }
}

# messager
resource "kubernetes_config_map" "messager" {
  metadata {
    name      = "messager-config-map"
    namespace = "gateway"
  }
  data = {
    "dev.env.json" = file("${path.module}/dev.messager.json")
  }
}

resource "kubernetes_config_map" "messager-chain" {
  metadata {
    name      = "messager-chain-config-map"
    namespace = "gateway"
  }
  data = {
    "testnet.json" = file("${path.module}/dev.chain.json")
  }
}

resource "kubernetes_deployment" "messager" {
  metadata {
    name      = "messager"
    labels = {
      app = "messager"
    }
    namespace = "gateway"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "messager"
      }
    }
    template {
      metadata {
        labels = {
          app = "messager"
        }
      }
      spec {
        container {
          name  = "messager"
          image = "asia-northeast1-docker.pkg.dev/orbital-builder-316023/docker-repository/octopus-gateway-messager:0.0.1"
          port {
            container_port = 7004
          }
          volume_mount {
            name       = "messager-config-volume"
            mount_path = "/app/messager/config/env"
          }
          volume_mount {
            name       = "messager-chain-volume"
            mount_path = "/app/messager/config/testnet.json"
            sub_path = "testnet.json"
          }
          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
        }
        volume {
          name = "messager-config-volume"
          config_map {
            name = kubernetes_config_map.messager.metadata.0.name
          }
        }
        volume {
          name = "messager-chain-volume"
          config_map {
            name = kubernetes_config_map.messager-chain.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "messager" {
  metadata {
    name     = "messager"
    namespace = "gateway"
  }
  spec {
    type = "ClusterIP"
    selector = {
      app = kubernetes_deployment.messager.metadata.0.labels.app
    }
    # session_affinity = "ClientIP"
    port {
      port        = 7004
      target_port = 7004
    }
  }
}

# stat
resource "kubernetes_config_map" "stat" {
  metadata {
    name      = "stat-config-map"
    namespace = "gateway"
  }
  data = {
      "dev.env.json" = file("${path.module}/dev.stat.json")
  }
}

resource "kubernetes_secret" "stat" {
  metadata {
    name      = "stat-secret"
    namespace = "gateway"
  }
  data = {
    REDIS_HOST     = var.redis_host
    REDIS_PORT     = var.redis_port
    REDIS_PASSWORD = var.redis_password
    REDIS_TLS_CRT  = var.redis_cert
  }
}

resource "kubernetes_deployment" "stat" {
  metadata {
    name      = "stat"
    labels = {
      app = "stat"
    }
    namespace = "gateway"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "stat"
      }
    }
    template {
      metadata {
        labels = {
          app = "stat"
        }
      }
      spec {
        container {
          name  = "stat"
          image = "asia-northeast1-docker.pkg.dev/orbital-builder-316023/docker-repository/octopus-gateway-stat:0.0.1"
          port {
            container_port = 7002
          }
          volume_mount {
            name       = "stat-config-volume"
            mount_path = "/app/stat/config/env"
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.stat.metadata.0.name
            }
          }
          resources {
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "256Mi"
            }
          }
        }
        volume {
          name = "stat-config-volume"
          config_map {
            name = kubernetes_config_map.stat.metadata.0.name
          }
        }
      }
    }
  }
}


resource "kubernetes_service" "stat" {
  metadata {
    name     = "stat"
    namespace = "gateway"
  }
  spec {
    type = "ClusterIP"
    selector = {
      app = kubernetes_deployment.stat.metadata.0.labels.app
    }
    # session_affinity = "ClientIP"
    port {
      port        = 7002
      target_port = 7002
    }
  }
}
