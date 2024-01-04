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

resource "kubernetes_cluster_role_v1" "default" {
  metadata {
    name = "prometheus-cluster-role"
  }
  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_service_account_v1" "default" {
  metadata {
    name      = "prometheus-service-account"
    namespace = var.namespace
  }
  # automount_service_account_token = false
}

resource "kubernetes_cluster_role_binding_v1" "default" {
  metadata {
    name = "prometheus-cluster-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.default.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account_v1.default.metadata.0.name
    namespace = var.namespace
  }
}

resource "kubernetes_config_map" "default" {
  metadata {
    name      = "prometheus-config-map"
    namespace = var.namespace
  }
  data = {
    "prometheus.yml" = <<-EOT
      global:
        scrape_interval: 15s
        evaluation_interval: 15s
        scrape_timeout: 5s
      scrape_configs:
      - honor_labels: true
        job_name: kubernetes-pods
        kubernetes_sd_configs:
        - role: pod
        relabel_configs:
        - action: keep
          regex: true
          source_labels:
          - __meta_kubernetes_pod_annotation_prometheus_io_scrape
        - action: drop
          regex: true
          source_labels:
          - __meta_kubernetes_pod_annotation_prometheus_io_scrape_slow
        - action: replace
          regex: (https?)
          source_labels:
          - __meta_kubernetes_pod_annotation_prometheus_io_scheme
          target_label: __scheme__
        - action: replace
          regex: (.+)
          source_labels:
          - __meta_kubernetes_pod_annotation_prometheus_io_path
          target_label: __metrics_path__
        - action: replace
          regex: (\d+);(([A-Fa-f0-9]{1,4}::?){1,7}[A-Fa-f0-9]{1,4})
          replacement: '[$2]:$1'
          source_labels:
          - __meta_kubernetes_pod_annotation_prometheus_io_port
          - __meta_kubernetes_pod_ip
          target_label: __address__
        - action: replace
          regex: (\d+);((([0-9]+?)(\.|$)){4})
          replacement: $2:$1
          source_labels:
          - __meta_kubernetes_pod_annotation_prometheus_io_port
          - __meta_kubernetes_pod_ip
          target_label: __address__
        - action: labelmap
          regex: __meta_kubernetes_pod_annotation_prometheus_io_param_(.+)
          replacement: __param_$1
        - action: labelmap
          regex: __meta_kubernetes_pod_label_(.+)
        - action: replace
          source_labels:
          - __meta_kubernetes_namespace
          target_label: namespace
        - action: replace
          source_labels:
          - __meta_kubernetes_pod_name
          target_label: pod
        - action: drop
          regex: Pending|Succeeded|Failed|Completed
          source_labels:
          - __meta_kubernetes_pod_phase
        - action: replace
          source_labels:
          - __meta_kubernetes_pod_node_name
          target_label: node
    EOT
  }
}

resource "kubernetes_service" "default" {
  metadata {
    name      = "prometheus"
    namespace = var.namespace
    labels = {
      app = "prometheus"
    }
  }
  spec {
    type = "ClusterIP"
    port {
      port        = 9090
      target_port = 9090
      protocol    = "TCP"
      name        = "http"
    }
    selector = {
      app = "prometheus"
    }
  }
}

resource "kubernetes_deployment" "default" {
  metadata {
    name      = "prometheus"
    namespace = var.namespace
    labels = {
      app = "prometheus"
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app = "prometheus"
      }
    }
    template {
      metadata {
        labels = {
          app = "prometheus"
        }
      }
      spec {
        container {
          name  = "prometheus"
          image = "prom/prometheus:v2.45.2"
          args = [
            "--storage.tsdb.retention.size=1GB",
            "--config.file=/etc/config/prometheus.yml",
            "--storage.tsdb.path=/data",
            # "--web.console.libraries=/etc/prometheus/console_libraries",
            # "--web.console.templates=/etc/prometheus/consoles",
            # "--web.enable-lifecycle",
          ]
          port {
            container_port = 9090
          }
          volume_mount {
            name       = "prometheus-config-volume"
            mount_path = "/etc/config"
          }
          volume_mount {
            name       = "prometheus-data-volume"
            mount_path = "/data"
            sub_path   = ""
          }
          resources {
            limits = {
              cpu    = var.resources.cpu_limits
              memory = var.resources.memory_limits
            }
            requests = {
              cpu    = var.resources.cpu_requests
              memory = var.resources.memory_requests
            }
          }
          readiness_probe {
            http_get {
              path   = "/-/ready"
              port   = 9090
              scheme = "HTTP"
            }
            initial_delay_seconds = 30
            period_seconds        = 5
            timeout_seconds       = 3
          }
          liveness_probe {
            http_get {
              path   = "/-/healthy"
              port   = 9090
              scheme = "HTTP"
            }
            initial_delay_seconds = 30
            period_seconds        = 15
            timeout_seconds       = 10
          }
        }
        volume {
          name = "prometheus-config-volume"
          config_map {
            name = kubernetes_config_map.default.metadata.0.name
          }
        }
        volume {
          name = "prometheus-data-volume"
          empty_dir {}
        }
        enable_service_links             = true
        service_account_name             = kubernetes_service_account_v1.default.metadata.0.name
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
