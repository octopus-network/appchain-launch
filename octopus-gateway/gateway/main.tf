
locals {
  dev_api_json = templatefile("${path.module}/dev.api.tpl", {
    messengers = jsonencode({for x in var.chains : x.name => ["ws://messenger:7004"]})
  })

  dev_messenger_json = templatefile("${path.module}/dev.messenger.tpl", {
    chain = jsonencode({for x in var.chains : x.name => {
      rpc = ["http://${x.service}:9933"]
      ws = ["ws://${x.service}:9944"]
      processors = ["node", "cache"]
    }})
  })

  dev_stat_json = templatefile("${path.module}/dev.stat.tpl", {
    chain = jsonencode({for x in var.chains : x.name => {}})
  })
}

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
    "dev.env.json" = local.dev_api_json
  }
}

resource "kubernetes_deployment" "api" {
  metadata {
    name = "api"
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
          image = var.gateway.api_image
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
    name      = "api"
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

# messenger
resource "kubernetes_config_map" "messenger" {
  metadata {
    name      = "messenger-config-map"
    namespace = "gateway"
  }
  data = {
    "dev.env.json" = local.dev_messenger_json
  }
}

resource "kubernetes_config_map" "messenger-chain" {
  metadata {
    name      = "messenger-chain-config-map"
    namespace = "gateway"
  }
  data = {
    for x in var.chains : "${x.name}.json" => file("${path.module}/dev.chain.json")
  }
}

resource "kubernetes_deployment" "messenger" {
  metadata {
    name = "messenger"
    labels = {
      app = "messenger"
    }
    namespace = "gateway"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "messenger"
      }
    }
    template {
      metadata {
        labels = {
          app = "messenger"
        }
      }
      spec {
        container {
          name  = "messenger"
          image = var.gateway.messenger_image
          port {
            container_port = 7004
          }
          volume_mount {
            name       = "messenger-config-volume"
            mount_path = "/app/messenger/config/env"
          }
          dynamic "volume_mount" {
            for_each = toset([for x in var.chains : x.name])
            content {
              name       = "messenger-chain-volume"
              mount_path = "/app/messenger/config/${volume_mount.key}.json"
              sub_path = "${volume_mount.key}.json"
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
          name = "messenger-config-volume"
          config_map {
            name = kubernetes_config_map.messenger.metadata.0.name
          }
        }
        volume {
          name = "messenger-chain-volume"
          config_map {
            name = kubernetes_config_map.messenger-chain.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "messenger" {
  metadata {
    name      = "messenger"
    namespace = "gateway"
  }
  spec {
    type = "ClusterIP"
    selector = {
      app = kubernetes_deployment.messenger.metadata.0.labels.app
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
    "dev.env.json" = local.dev_stat_json
  }
}

resource "kubernetes_secret" "stat" {
  metadata {
    name      = "stat-secret"
    namespace = "gateway"
  }
  data = {
    REDIS_HOST     = var.redis.host
    REDIS_PORT     = var.redis.port
    REDIS_PASSWORD = var.redis.password
    REDIS_TLS_CRT  = var.redis.tls_cert
  }
}

resource "kubernetes_deployment" "stat" {
  metadata {
    name = "stat"
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
          image = var.gateway.stat_image
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
    name      = "stat"
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
