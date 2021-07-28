
locals {
  dev_api_json = templatefile("${path.module}/dev.api.tpl", {
    messengers = jsonencode({for x in var.chains : x.name => ["ws://messenger:7004"]})
    pubsub     = jsonencode({
      topic = var.pubsub.topic
      subscription = var.pubsub.subscription
    })
  })

  dev_messenger_json = templatefile("${path.module}/dev.messenger.tpl", {
    chain = jsonencode({for x in var.chains : x.name => {
      rpc = ["http://${x.service}:9933"]
      ws = ["ws://${x.service}:9944"]
      processors = ["node", "cache"]
    }})
  })

  dev_stat_json = templatefile("${path.module}/dev.stat.tpl", {
    chain  = jsonencode({for x in var.chains : x.name => {}})
    pubsub = jsonencode({
      topic = var.pubsub.topic
      subscription = var.pubsub.subscription
    })
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

# sa key
resource "kubernetes_secret" "pubsub" {
  metadata {
    name      = "pubsub-key-secret"
    namespace = "gateway"
  }
  data = {
    "sa-key.json" = file(var.pubsub.sa_key)
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
          volume_mount {
            name       = "api-pubsub-secret"
            mount_path = "/app/certs"
          }
          env {
            name  = "GOOGLE_APPLICATION_CREDENTIALS"
            value = "/app/certs/sa-key.json"
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
        volume {
          name = "api-pubsub-secret"
          secret {
            secret_name = kubernetes_secret.pubsub.metadata.0.name
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
    annotations = {
      "cloud.google.com/neg" = "{\"ingress\": true}"
    }
  }
  spec {
    type = "NodePort" # "ClusterIP"
    selector = {
      app = kubernetes_deployment.api.metadata.0.labels.app
    }
    # session_affinity = "ClientIP"
    port {
      port        = 7003
      target_port = 7003
      protocol    = "TCP"
    }
  }
}

resource "google_compute_global_address" "api" {
  name  = "gateway-global-address"
}

resource "google_compute_managed_ssl_certificate" "api" {
  name = "gateway-testnet-octopus-network"
  managed {
    domains = var.gateway.api_domains
  }
}

# TODO: terraform not support cloud.google.com/backend-config (health check, ws timeout)
resource "kubernetes_ingress" "api" {
  metadata {
    name        = "api-ingress"
    namespace   = "gateway"
    annotations = {
      "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.api.name
      "networking.gke.io/managed-certificates"      = google_compute_managed_ssl_certificate.api.name
      "kubernetes.io/ingress.class"                 = "gce"
      # "kubernetes.io/ingress.allow-http"            = false
    }
  }
  spec {
    backend {
      service_name = kubernetes_service.api.metadata.0.name
      service_port = 7003
    }
    rule {
      http {
        dynamic "path" {
          for_each = toset(["stat", "project", "plugins", "assets"])
          content {
            backend {
              service_name = kubernetes_service.stat.metadata.0.name
              service_port = 7002
            }
            path = "/${path.key}/*"
          }
        }
        path {
          backend {
            service_name = kubernetes_service.stat.metadata.0.name
            service_port = 7002
          }
          path = "/dashboard"
        }
        # path {
        #   backend {
        #     service_name = kubernetes_service.api.metadata.0.name
        #     service_port = 7003
        #   }
        #   path = "/*"
        # }
      }
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
    type = "NodePort" # "ClusterIP"
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

# stat-sub
resource "kubernetes_deployment" "stat-sub" {
  metadata {
    name = "stat-sub"
    labels = {
      app = "stat-sub"
    }
    namespace = "gateway"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "stat-sub"
      }
    }
    template {
      metadata {
        labels = {
          app = "stat-sub"
        }
      }
      spec {
        container {
          name    = "stat-sub"
          image   = var.gateway.stat_image
          command = ["node", "stat/pubsub/consumer.js"]
          volume_mount {
            name       = "stat-config-volume"
            mount_path = "/app/stat/config/env"
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.stat.metadata.0.name
            }
          }
          volume_mount {
            name       = "stat-pubsub-secret"
            mount_path = "/app/certs"
          }
          env {
            name  = "GOOGLE_APPLICATION_CREDENTIALS"
            value = "/app/certs/sa-key.json"
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
        volume {
          name = "stat-pubsub-secret"
          secret {
            secret_name = kubernetes_secret.pubsub.metadata.0.name
          }
        }
      }
    }
  }
}

# stat-cronjob
resource "kubernetes_cron_job" "stat-cron" {
  metadata {
    name = "stat-cron"
    namespace = "gateway"
  }
  spec {
    concurrency_policy            = "Forbid"
    schedule                      = "* * * * *"
    # failed_jobs_history_limit     = 5
    # starting_deadline_seconds     = 10
    # successful_jobs_history_limit = 10
    job_template {
      metadata {}
      spec {
        template {
          metadata {}
          spec {
            container {
              name    = "stat-cron"
              image   = var.gateway.stat_image
              command = ["node", "stat/timer/dashboard.js"]
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
        # backoff_limit              = 3
        ttl_seconds_after_finished = 30
      }
    }
  }
}
