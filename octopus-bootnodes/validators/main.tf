data "kubernetes_namespace" "default" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_stateful_set" "default" {
  metadata {
    name      = "${var.chain_name}-validators-${var.deploy_version}"
    namespace = data.kubernetes_namespace.default.metadata.0.name
    labels = {
      name  = "${var.chain_name}-validators-${var.deploy_version}"
      app   = "validators-${var.deploy_version}"
      chain = var.chain_name
    }
  }
  spec {
    service_name           = "${var.chain_name}-validators-${var.deploy_version}"
    pod_management_policy  = "Parallel"
    replicas               = var.replicas
    revision_history_limit = 5
    selector {
      match_labels = {
        name  = "${var.chain_name}-validators-${var.deploy_version}"
        app   = "validators-${var.deploy_version}"
        chain = var.chain_name
      }
    }
    template {
      metadata {
        labels = {
          name  = "${var.chain_name}-validators-${var.deploy_version}"
          app   = "validators-${var.deploy_version}"
          chain = var.chain_name
        }
      }
      spec {
        container {
          name    = "validators"
          image   = var.base_image
          command = [var.start_cmd]
          args = concat([
            "--chain",
            var.chain_spec,
            "--base-path",
            "/substrate/data",
            "--port",
            "30333",
            "--rpc-external",
            "--rpc-cors",
            "all",
            "--rpc-methods",
            "Unsafe",
            "--validator",
            "--prometheus-external",
            "--prometheus-port",
            "9615",
            "--enable-offchain-indexing",
            "true",
            "--telemetry-url",
            "${var.telemetry_url}"
          ], flatten([for i, x in var.bootnodes: ["--bootnodes", x]]))
          port {
            container_port = 9933
          }
          port {
            container_port = 30333
          }
          port {
            container_port = 9615
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
            name       = "validators-data-volume-${var.deploy_version}"
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
        security_context {
          fs_group = 1000
        }
        # affinity {
        #   pod_anti_affinity {
        #     required_during_scheduling_ignored_during_execution {
        #       label_selector {
        #         match_expressions {
        #           key      = "app"
        #           operator = "In"
        #           values   = ["validators"]
        #         }
        #       }
        #       topology_key = "kubernetes.io/hostname"
        #     }
        #     preferred_during_scheduling_ignored_during_execution {
        #       weight = 100
        #       pod_affinity_term {
        #         label_selector {
        #           match_expressions {
        #             key      = "app"
        #             operator = "In"
        #             values   = ["validators"]
        #           }
        #         }
        #         topology_key = "topology.kubernetes.io/zone"
        #       }
        #     }
        #   }
        # }
        termination_grace_period_seconds = 300
      }
    }
    volume_claim_template {
      metadata {
        name      = "validators-data-volume-${var.deploy_version}"
        namespace = data.kubernetes_namespace.default.metadata.0.name
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
  count = var.replicas
  metadata {
    name      = "${var.chain_name}-validators-${var.deploy_version}-${count.index}"
    namespace = data.kubernetes_namespace.default.metadata.0.name
    labels = {
      name  = "${var.chain_name}-validators-${var.deploy_version}"
      app   = "validators-${var.deploy_version}"
      chain = var.chain_name
    }
  }
  spec {
    selector = {
      "statefulset.kubernetes.io/pod-name" = "${var.chain_name}-validators-${var.deploy_version}-${count.index}"
    }
    session_affinity = "ClientIP"
    port {
      name        = "p2p"
      protocol    = "TCP"
      port        = 30333
      target_port = 30333
    }
    port {
      name        = "metrics"
      port        = 9615
      target_port = 9615
    }
    type                    = "LoadBalancer"
    external_traffic_policy = "Local"
  }
}

resource "kubernetes_service" "internal" {
  count = var.replicas
  metadata {
    name      = "${var.chain_name}-validators-${var.deploy_version}-${count.index}-internal"
    namespace = data.kubernetes_namespace.default.metadata.0.name
    labels = {
      name  = "${var.chain_name}-validators-${var.deploy_version}"
      app   = "validators-${var.deploy_version}"
      chain = var.chain_name
    }
  }
  spec {
    selector = {
      "statefulset.kubernetes.io/pod-name" = "${var.chain_name}-validators-${var.deploy_version}-${count.index}"
    }
    port {
      name        = "rpc"
      port        = 9933
      target_port = 9933
    }
    type = "ClusterIP"
  }
}

module "add-keys" {
  source            = "./add-keys"
  chain_name        = var.chain_name
  keys_octoup       = var.keys_octoup
  module_depends_on = [kubernetes_stateful_set.default]
  namespace         = data.kubernetes_namespace.default.metadata.0.name
  deploy_version    = var.deploy_version
}
