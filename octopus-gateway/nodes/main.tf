resource "kubernetes_namespace" "default" {
  metadata {
    labels = {
      name = var.chain_name
    }
    name = var.chain_name
  }
}

resource "kubernetes_stateful_set" "default" {
  metadata {
    name      = "fullnode"
    namespace = var.chain_name
  }
  spec {
    service_name           = "fullnode"
    pod_management_policy  = "Parallel"
    replicas               = var.replicas
    revision_history_limit = 5
    selector {
      match_labels = {
        app = "fullnode"
      }
    }
    template {
      metadata {
        labels = {
          app = "fullnode"
        }
      }
      spec {
        init_container {
          name              = "init-chainspec"
          image             = "busybox"
          image_pull_policy = "IfNotPresent"
          command           = ["wget", "-O", "/substrate/chainSpec.json", var.chainspec_url]
          resources {
            limits = {
              cpu    = "100m"
              memory = "100Mi"
            }
            requests = {
              cpu    = "100m"
              memory = "100Mi"
            }
          }
          volume_mount {
            name       = "fullnode-data"
            mount_path = "/substrate"
          }
        }
        container {
          name              = "fullnode"
          image             = var.base_image
          image_pull_policy = "IfNotPresent"
          command = [var.start_cmd]
          args = concat([
            "--chain",
            "/substrate/chainSpec.json",
            "--base-path",
            "/substrate/data",
            "--ws-external",
            "--rpc-external",
            "--rpc-cors",
            "all",
            "--no-telemetry",
            "--prometheus-external",
            "--prometheus-port",
            "9615",
            "--wasm-execution",
            "Compiled"],
            flatten([for x in var.bootnodes : ["--bootnodes", x]]))
          port {
            container_port = 9933
          }
          port {
            container_port = 9944
          }
          port {
            container_port = 9615
          }
          port {
            container_port = 30333
          }
          resources {
            limits = {
              cpu    = var.cpu_limits
              memory = var.memory_limits
            }
            requests = {
              cpu    = var.cpu_requests
              memory = var.memory_requests
            }
          }
          volume_mount {
            name       = "fullnode-data"
            mount_path = "/substrate"
          }
          readiness_probe {
            http_get {
              path = "/metrics"
              port = 9615
            }
            initial_delay_seconds = 10
            timeout_seconds       = 1
          }
          liveness_probe {
            http_get {
              path   = "/metrics"
              port   = 9615
            }
            initial_delay_seconds = 10
            timeout_seconds       = 1
          }
        }
        volume {
          name = "fullnode-config"
          config_map {
            name = "fullnode-config-map"
          }
        }
        security_context {
          fs_group = 1000
        }
        termination_grace_period_seconds = 300
      }
    }
    volume_claim_template {
      metadata {
        name = "fullnode-data"
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = var.volume_type
        resources {
          requests = {
            storage = var.volume_size
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "default" {
  metadata {
    name      = "fullnode"
    namespace = var.chain_name
  }
  spec {
    port {
      name        = "rpc"
      port        = 9933
      target_port = 9933
    }
    port {
      name        = "ws"
      port        = 9944
      target_port = 9944
    }
    cluster_ip = "None"
    selector = {
      app = "fullnode"
    }
    session_affinity = "ClientIP"
  }
}

