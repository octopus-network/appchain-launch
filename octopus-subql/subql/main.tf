resource "kubernetes_secret" "default" {
  metadata {
    name      = "${var.appchain_id}-subsql-secret"
    namespace = var.namespace
  }
  data = {
    DB_USER     = var.database.username
    DB_PASS     = var.database.password
    DB_DATABASE = var.database.database
  }
}

resource "kubernetes_config_map" "default" {
  metadata {
    name      = "${var.appchain_id}-subsql-config-map"
    namespace = var.namespace
  }
  data = {
    APPCHAIN_ID         = var.appchain_id
    APPCHAIN_ENDPOINT   = var.appchain_endpoint
    GCE_PROXY_INSTANCES = var.gce_proxy_instances
  }
}

resource "kubernetes_deployment" "default" {
  metadata {
    name = "${var.appchain_id}-subsql"
    labels = {
      name  = "${var.appchain_id}-subql"
      app   = "subql"
      chain = var.appchain_id
    }
    namespace = var.namespace
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        name  = "${var.appchain_id}-subql"
        app   = "subql"
        chain = var.appchain_id
      }
    }
    template {
      metadata {
        labels = {
          name  = "${var.appchain_id}-subql"
          app   = "subql"
          chain = var.appchain_id
        }
      }
      spec {
        container {
          name    = "cloud-sql-proxy"
          image   = var.gce_proxy_image
          command = ["/cloud_sql_proxy", "-instances=$(GCE_PROXY_INSTANCES)"]
          env_from {
            config_map_ref {
              name = kubernetes_config_map.default.metadata.0.name
            }
          }
          resources {
            requests = {
              cpu    = "1000m"
              memory = "2048Mi"
            }
          }
          security_context {
            run_as_non_root = true
          }
        }
        container {
          name  = "subql-node"
          image = var.subql_node_image
          args  = [
            "-f=/workdir",
            "--subquery-name=$(APPCHAIN_ID)",
            "--migrate",
            "--network-endpoint=$(APPCHAIN_ENDPOINT)"
          ]
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
              cpu    = "200m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }
        container {
          name  = "subql-query"
          image = var.subql_query_image
          args  = [ "--name=$(APPCHAIN_ID)", "--playground"]
          port {
            container_port = 3001
          }
          env {
            name  = "PORT"
            value = 3001
          }
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
              cpu    = "200m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
            }
          }
        }
        service_account_name = var.service_account
      }
    }
  }
}

resource "kubernetes_service" "default" {
  metadata {
    name        = "${var.appchain_id}-subql"
    namespace   = var.namespace
    labels = {
      name  = "${var.appchain_id}-subql"
      app   = "subql"
      chain = var.appchain_id
    }
    annotations = {
      "cloud.google.com/neg" = "{\"ingress\": true}"
    }
  }
  spec {
    type = "NodePort"
    selector = {
      name  = "${var.appchain_id}-subql"
      app   = "subql"
      chain = var.appchain_id
    }
    port {
      port        = 3001
      target_port = 3001
      protocol    = "TCP"
    }
  }
}
