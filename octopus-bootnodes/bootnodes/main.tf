resource "google_compute_address" "default" {
  count = var.replicas
  name  = "ip-${var.chain_name}-${var.deploy_version}-${count.index}"
}

data "google_dns_managed_zone" "default" {
  name = var.dns_zone
}

resource "google_dns_record_set" "default" {
  count        = var.replicas
  name         = "bootnode-${var.deploy_version}-${count.index}.${var.chain_name}.${data.google_dns_managed_zone.default.dns_name}"
  managed_zone = data.google_dns_managed_zone.default.name
  type         = "A"
  ttl          = 300
  rrdatas = [google_compute_address.default.*.address[count.index]]
}

locals {
  bootnodes = [
    for idx, addr in google_compute_address.default.*.address:
      "/ip4/${addr}/tcp/30333/ws/p2p/${var.keys_octoup[idx]["peer-id"]}"
  ]

  bootnodes_dns = [
    for idx, addr in google_compute_address.default.*.address:
      "/dns/bootnode-${var.deploy_version}-${idx}.${var.chain_name}.${trimsuffix(data.google_dns_managed_zone.default.dns_name, ".")}/tcp/30333/ws/p2p/${var.keys_octoup[idx]["peer-id"]}"
  ]
}

# k8s
data "kubernetes_namespace" "default" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_config_map" "default" {
  metadata {
    name      = "${var.chain_name}-bootnodes-config-map-${var.deploy_version}"
    namespace = data.kubernetes_namespace.default.metadata.0.name
  }
  data = {
    for i, v in var.keys_octoup: "node-key-${i}" => v["node-key"]
  }
}

resource "kubernetes_stateful_set" "default" {
  count = var.replicas
  metadata {
    name      = "${var.chain_name}-bootnodes-${var.deploy_version}-${count.index}"
    namespace = data.kubernetes_namespace.default.metadata.0.name
    labels = {
      name  = "${var.chain_name}-bootnodes-${var.deploy_version}-${count.index}"
      app   = "bootnodes-${var.deploy_version}"
      chain = var.chain_name
    }
  }
  spec {
    service_name           = "${var.chain_name}-bootnodes-${var.deploy_version}-${count.index}"
    pod_management_policy  = "Parallel"
    replicas               = 1
    revision_history_limit = 5
    selector {
      match_labels = {
        name  = "${var.chain_name}-bootnodes-${var.deploy_version}-${count.index}"
        app   = "bootnodes-${var.deploy_version}"
        chain = var.chain_name
      }
    }
    template {
      metadata {
        labels = {
          name  = "${var.chain_name}-bootnodes-${var.deploy_version}-${count.index}"
          app   = "bootnodes-${var.deploy_version}"
          chain = var.chain_name
        }
      }
      spec {
        container {
          name    = "bootnodes"
          image   = var.base_image
          command = [var.start_cmd]
          args = concat([
            "--chain",
            var.chain_spec,
            "--node-key-file",
            "/substrate/.node-key",
            "--base-path",
            "/substrate/data",
            "--port",
            "30333",
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
            name       = "bootnodes-data-volume-${var.deploy_version}"
            mount_path = "/substrate"
          }
          volume_mount {
            name       = "bootnodes-config-volume-${var.deploy_version}"
            mount_path = "/substrate/.node-key"
            sub_path   = "node-key-${count.index}"
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
        volume {
          name = "bootnodes-config-volume-${var.deploy_version}"
          config_map {
            name = kubernetes_config_map.default.metadata.0.name
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
        #           values   = ["bootnodes"]
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
        #             values   = ["bootnodes"]
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
        name      = "bootnodes-data-volume-${var.deploy_version}"
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
  lifecycle {
    ignore_changes = [
      spec[0].template[0].spec[0].container[0].resources
    ]
  }
}

resource "kubernetes_service" "default" {
  count = var.replicas
  metadata {
    name      = "${var.chain_name}-bootnodes-${var.deploy_version}-${count.index}"
    namespace = data.kubernetes_namespace.default.metadata.0.name
    labels = {
      name  = "${var.chain_name}-bootnodes-${var.deploy_version}-${count.index}"
      app   = "bootnodes-${var.deploy_version}"
      chain = var.chain_name
    }
  }
  spec {
    selector = {
      name = "${var.chain_name}-bootnodes-${var.deploy_version}-${count.index}"
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
    load_balancer_ip        = google_compute_address.default[count.index].address
    external_traffic_policy = "Local"
  }
}

output "bootnodes" {
  description = ""
  value       = local.bootnodes
}

output "bootnodes_dns" {
  description = ""
  value       = local.bootnodes_dns
}
