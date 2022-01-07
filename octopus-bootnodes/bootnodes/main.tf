resource "google_compute_address" "default" {
  count = var.replicas
  name  = "ip-${var.chain_name}-${count.index}"
}

data "google_dns_managed_zone" "default" {
  name = var.dns_zone
}

resource "google_dns_record_set" "default" {
  count        = var.replicas
  name         = "bootnode-${count.index}.${var.chain_name}.${data.google_dns_managed_zone.default.dns_name}"
  managed_zone = data.google_dns_managed_zone.default.name
  type         = "A"
  ttl          = 300
  rrdatas = [google_compute_address.default.*.address[count.index]]
}

locals {
  keys_octoup = [
    for i in range(var.replicas): {
      peer_id = chomp(file("${var.keys_octoup}/${i}/peer-id"))
      node_key = chomp(file("${var.keys_octoup}/${i}/node-key"))
    }
  ]

  bootnodes = [
    for idx, addr in google_compute_address.default.*.address:
      "/ip4/${addr}/tcp/30333/ws/p2p/${local.keys_octoup[idx]["peer_id"]}"
  ]

  bootnodes_dns = [
    for idx, addr in google_compute_address.default.*.address:
      "/ip4/bootnode-${idx}.${var.chain_name}.${trimsuffix(data.google_dns_managed_zone.default.dns_name, ".")}/tcp/30333/ws/p2p/${local.keys_octoup[idx]["peer_id"]}"
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
    name      = "${var.chain_name}-bootnodes-config-map"
    namespace = data.kubernetes_namespace.default.metadata.0.name
  }
  data = {
    for i, v in local.keys_octoup: "node-key-${i}" => v["node_key"]
  }
}

resource "kubernetes_stateful_set" "default" {
  metadata {
    name      = "${var.chain_name}-bootnodes"
    namespace = data.kubernetes_namespace.default.metadata.0.name
    labels = {
      name  = "${var.chain_name}-bootnodes"
      app   = "bootnodes"
      chain = var.chain_name
    }
  }
  spec {
    service_name           = "${var.chain_name}-bootnodes"
    pod_management_policy  = "Parallel"
    replicas               = var.replicas
    revision_history_limit = 5
    selector {
      match_labels = {
        name  = "${var.chain_name}-bootnodes"
        app   = "bootnodes"
        chain = var.chain_name
      }
    }
    template {
      metadata {
        labels = {
          name  = "${var.chain_name}-bootnodes"
          app   = "bootnodes"
          chain = var.chain_name
        }
      }
      spec {
        init_container {
          name    = "init-nodekey"
          image   = "busybox"
          command = ["sh", "-c", "cp /tmp/node-key-$${HOSTNAME##*-} /substrate/.node-key"]
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
            name       = "bootnodes-data-volume"
            mount_path = "/substrate"
          }
          volume_mount {
            name       = "bootnodes-config-volume"
            mount_path = "/tmp"
          }
        }
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
            "--pruning",
            "archive",
            "--prometheus-external",
            "--prometheus-port",
            "9615",
            "--enable-offchain-indexing",
            "true",
            "--telemetry-url",
            "${var.telemetry_url}"
          ], flatten([for i, x in []: ["--bootnodes", x]]))
          port {
            container_port = 9933
          }
          port {
            container_port = 30333
          }
          port {
            container_port = 9615
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
            name       = "bootnodes-data-volume"
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
        volume {
          name = "bootnodes-config-volume"
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
        name      = "bootnodes-data-volume"
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
    name      = "${var.chain_name}-bootnodes-${count.index}"
    namespace = data.kubernetes_namespace.default.metadata.0.name
    labels = {
      name  = "${var.chain_name}-bootnodes"
      app   = "bootnodes"
      chain = var.chain_name
    }
  }
  spec {
    selector = {
      "statefulset.kubernetes.io/pod-name" = "${var.chain_name}-bootnodes-${count.index}"
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
