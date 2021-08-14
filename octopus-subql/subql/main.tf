

resource "kubernetes_service_account" "default" {
  metadata {
    name = "${var.appchain_id}-subql-ksa"
    namespace = var.appchain_id
    annotations = {
      "iam.gke.io/gcp-service-account" = var.service_account
    }
  }
}

data "google_service_account" "default" {
  account_id = var.service_account
}

resource "google_service_account_iam_member" "default" {
  service_account_id = data.google_service_account.default.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project}.svc.id.goog[${var.appchain_id}/${var.appchain_id}-subql-ksa]"
}

resource "kubernetes_secret" "default" {
  metadata {
    name      = "${var.appchain_id}-secret"
    namespace = var.appchain_id
  }
  data = {
    DB_USER     = var.database.username
    DB_PASS     = var.database.password
    DB_DATABASE = var.database.database
  }
}

resource "kubernetes_deployment" "default" {
  metadata {
    name = "${var.appchain_id}-subsql"
    labels = {
      app = "subql"
    }
    namespace = var.appchain_id
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "subql"
      }
    }
    template {
      metadata {
        labels = {
          app = "subql"
        }
      }
      spec {
        container {
          name    = "cloud-sql-proxy"
          image   = var.gce_proxy_image
          command = ["/cloud_sql_proxy", "-instances=${var.gce_proxy_instances}"]
          resources {
            requests = {
              cpu    = "500m"
              memory = "512Mi"
            }
            limits = {
              cpu    = "500m"
              memory = "512Mi"
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
            "--subquery-name=${var.appchain_id}",
            "--migrate",
            "--network-endpoint=${var.appchain_endpoint}"
          ]
          env_from {
            secret_ref {
              name = kubernetes_secret.default.metadata.0.name
            }
          }
          resources {
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
        container {
          name  = "subql-query"
          image = var.subql_query_image
          args  = [ "--name=${var.appchain_id}", "--playground"]
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
          resources {
            requests = {
              cpu    = "200m"
              memory = "256Mi"
            }
            limits = {
              cpu    = "200m"
              memory = "256Mi"
            }
          }
        }
        service_account_name = "${var.appchain_id}-subql-ksa"
      }
    }
  }
}

resource "kubernetes_service" "default" {
  metadata {
    name        = "${var.appchain_id}-subql"
    namespace   = var.appchain_id
    annotations = {
      "cloud.google.com/neg" = "{\"ingress\": true}"
    }
  }
  spec {
    type = "NodePort"
    selector = {
      app = kubernetes_deployment.default.metadata.0.labels.app
    }
    port {
      port        = 3001
      target_port = 3001
      protocol    = "TCP"
    }
  }
}
