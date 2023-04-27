resource "kubernetes_secret" "default" {
  metadata {
    name      = "${var.chain_name}-fullnode-secret"
    namespace = var.namespace
  }
  data = {
    secret_phrase	= var.secret_phrase
  }
  count = var.enable_broker ? 1 : 0
}

resource "kubernetes_stateful_set" "default" {
  metadata {
    name      = "${var.chain_name}-fullnode"
    namespace = var.namespace
    labels = {
      name  = "${var.chain_name}-fullnode"
      app   = "fullnode"
      chain = var.chain_name
    }
  }
  spec {
    service_name           = "${var.chain_name}-fullnode"
    pod_management_policy  = "Parallel"
    replicas               = var.replicas
    revision_history_limit = 5
    selector {
      match_labels = {
        name  = "${var.chain_name}-fullnode"
        app   = "fullnode"
        chain = var.chain_name
      }
    }
    template {
      metadata {
        labels = {
          name  = "${var.chain_name}-fullnode"
          app   = "fullnode"
          chain = var.chain_name
        }
      }
      spec {
        container {
          name    = "fullnode"
          image   = var.base_image
          command = [var.start_cmd]
          args = concat([
            "--chain",
            var.chain_spec,
            "--base-path",
            "/substrate/data",
            "--ws-external",
            "--ws-max-connections",
            "2000",
            "--rpc-external",
            "--rpc-cors",
            "all",
            "--prometheus-external",
            "--prometheus-port",
            "9615",
            "--wasm-execution",
            "Compiled",
            "--enable-offchain-indexing",
            "true",
            "--pruning",
            "archive",
            "--telemetry-url",
            "${var.telemetry_url}"
          ], (var.enable_broker ? ["--relayer", "--rpc-methods", "Safe"] : ["--rpc-methods", "Unsafe"]))
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
          dynamic "env" {
            for_each = var.rust_log == "" ? []: [1]
            content {
              name = "RUST_LOG"
              value = var.rust_log
            }
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
            name       = "fullnode-data-volume"
            mount_path = "/substrate"
          }
          readiness_probe {
            http_get {
              path = "/health"
              port = 9933
            }
            initial_delay_seconds = 10
            timeout_seconds       = 1
          }
          liveness_probe {
            http_get {
              path   = "/health"
              port   = 9933
            }
            initial_delay_seconds = 10
            timeout_seconds       = 1
          }
        }
        dynamic init_container{
          for_each = var.enable_broker ? [1] : []
          content {
            name    = "insert-key"
            image   = var.base_image
            command = [var.start_cmd]
            args = [
              "key",
              "insert",
              "--chain",
              var.chain_spec,
              "--base-path",
              "/substrate/data",
              "--key-type",
              "rely",
              "--scheme",
              "sr25519",
              "--suri",
              "/tmp/secret_phrase"
            ]
            volume_mount {
              name       = "fullnode-data-volume"
              mount_path = "/substrate"
            }
            volume_mount {
              name       = "fullnode-secret-volume"
              mount_path = "/tmp/secret_phrase"
              sub_path   = "secret_phrase"
              read_only  = true
            }
          }
        }
        dynamic volume {
          for_each = var.enable_broker ? [1] : []
          content {
            name = "fullnode-secret-volume"
            secret {
              secret_name = kubernetes_secret.default[0].metadata.0.name
            }
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
        name = "fullnode-data-volume"
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
  lifecycle {
    ignore_changes = [
      spec[0].template[0].spec[0].container[0].resources
    ]
  }
}

resource "kubernetes_service" "default" {
  metadata {
    name      = "${var.chain_name}-fullnode"
    namespace = var.namespace
    labels = {
      name  = "${var.chain_name}-fullnode"
      app   = "fullnode"
      chain = var.chain_name
    }
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
      name  = "${var.chain_name}-fullnode"
      app   = "fullnode"
      chain = var.chain_name
    }
    session_affinity = "ClientIP"
  }
}
