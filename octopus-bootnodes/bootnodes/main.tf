resource "google_compute_address" "default" {
  count = local.offset
  name  = "ip-${var.chain_name}-${var.deploy_version}-${count.index}"
}

resource "google_compute_address" "region_2nd" {
  count    = local.offset
  name     = "ip-${var.chain_name}-${var.deploy_version}-${count.index + local.offset}"
  provider = google.gcp-2nd
}

data "google_dns_managed_zone" "default" {
  name = var.dns_zone
}

resource "google_dns_record_set" "default" {
  count        = local.offset
  name         = "bootnode-${var.deploy_version}-${count.index}.${var.chain_name}.${data.google_dns_managed_zone.default.dns_name}"
  managed_zone = data.google_dns_managed_zone.default.name
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_address.default.*.address[count.index]]
}

resource "google_dns_record_set" "region_2nd" {
  count        = local.offset
  name         = "bootnode-${var.deploy_version}-${count.index + local.offset}.${var.chain_name}.${data.google_dns_managed_zone.default.dns_name}"
  managed_zone = data.google_dns_managed_zone.default.name
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_address.region_2nd.*.address[count.index]]
}

locals {
  offset = var.replicas / 2

  bootnodes = concat([
    for idx, addr in google_compute_address.default.*.address :
    "/ip4/${addr}/tcp/30333/ws/p2p/${var.keys_octoup[idx]["peer-id"]}"
    ], [
    for idx, addr in google_compute_address.region_2nd.*.address :
    "/ip4/${addr}/tcp/30333/ws/p2p/${var.keys_octoup[idx + local.offset]["peer-id"]}"
  ])

  bootnodes_dns = concat([
    for idx, addr in google_compute_address.default.*.address :
    "/dns/bootnode-${var.deploy_version}-${idx}.${var.chain_name}.${trimsuffix(data.google_dns_managed_zone.default.dns_name, ".")}/tcp/30333/ws/p2p/${var.keys_octoup[idx]["peer-id"]}"
    ], [
    for idx, addr in google_compute_address.region_2nd.*.address :
    "/dns/bootnode-${var.deploy_version}-${idx + local.offset}.${var.chain_name}.${trimsuffix(data.google_dns_managed_zone.default.dns_name, ".")}/tcp/30333/ws/p2p/${var.keys_octoup[idx + local.offset]["peer-id"]}"
  ])
}

# k8s
resource "kubernetes_config_map" "default" {
  metadata {
    name      = "${var.chain_name}-bootnodes-config-map-${var.deploy_version}"
    namespace = var.namespace
  }
  data = {
    for i, v in var.keys_octoup : "node-key-${i}" => v["node-key"]
  }
}

resource "kubernetes_stateful_set" "default" {
  count = local.offset
  metadata {
    name      = "${var.chain_name}-bootnodes-${var.deploy_version}-${count.index}"
    namespace = var.namespace
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
            "--pruning",
            "archive",
            "--prometheus-external",
            "--prometheus-port",
            "9615",
            "--wasm-execution",
            "Compiled",
            "--enable-offchain-indexing",
            "true",
            "--telemetry-url",
            "${var.telemetry_url}"
          ], flatten([for i, x in var.bootnodes : ["--bootnodes", x]]))
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
              path = "/health"
              port = 9933
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
        namespace = var.namespace
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
  count = local.offset
  metadata {
    name      = "${var.chain_name}-bootnodes-${var.deploy_version}-${count.index}"
    namespace = var.namespace
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

resource "kubernetes_config_map" "region_2nd" {
  provider = kubernetes.gke-2nd
  metadata {
    name      = "${var.chain_name}-bootnodes-config-map-${var.deploy_version}"
    namespace = var.namespace
  }
  data = {
    for i, v in var.keys_octoup : "node-key-${i}" => v["node-key"]
  }
}

resource "kubernetes_stateful_set" "region_2nd" {
  provider = kubernetes.gke-2nd
  count    = local.offset
  metadata {
    name      = "${var.chain_name}-bootnodes-${var.deploy_version}-${count.index + local.offset}"
    namespace = var.namespace
    labels = {
      name  = "${var.chain_name}-bootnodes-${var.deploy_version}-${count.index + local.offset}"
      app   = "bootnodes-${var.deploy_version}"
      chain = var.chain_name
    }
  }
  spec {
    service_name           = "${var.chain_name}-bootnodes-${var.deploy_version}-${count.index + local.offset}"
    pod_management_policy  = "Parallel"
    replicas               = 1
    revision_history_limit = 5
    selector {
      match_labels = {
        name  = "${var.chain_name}-bootnodes-${var.deploy_version}-${count.index + local.offset}"
        app   = "bootnodes-${var.deploy_version}"
        chain = var.chain_name
      }
    }
    template {
      metadata {
        labels = {
          name  = "${var.chain_name}-bootnodes-${var.deploy_version}-${count.index + local.offset}"
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
            "--pruning",
            "archive",
            "--prometheus-external",
            "--prometheus-port",
            "9615",
            "--wasm-execution",
            "Compiled",
            "--enable-offchain-indexing",
            "true",
            "--telemetry-url",
            "${var.telemetry_url}"
          ], flatten([for i, x in var.bootnodes : ["--bootnodes", x]]))
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
            name       = "bootnodes-data-volume-${var.deploy_version}"
            mount_path = "/substrate"
          }
          volume_mount {
            name       = "bootnodes-config-volume-${var.deploy_version}"
            mount_path = "/substrate/.node-key"
            sub_path   = "node-key-${count.index + local.offset}"
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
              path = "/health"
              port = 9933
            }
            initial_delay_seconds = 10
            timeout_seconds       = 1
          }
        }
        volume {
          name = "bootnodes-config-volume-${var.deploy_version}"
          config_map {
            name = kubernetes_config_map.region_2nd.metadata.0.name
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
        name      = "bootnodes-data-volume-${var.deploy_version}"
        namespace = var.namespace
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

resource "kubernetes_service" "region_2nd" {
  provider = kubernetes.gke-2nd
  count    = local.offset
  metadata {
    name      = "${var.chain_name}-bootnodes-${var.deploy_version}-${count.index + local.offset}"
    namespace = var.namespace
    labels = {
      name  = "${var.chain_name}-bootnodes-${var.deploy_version}-${count.index + local.offset}"
      app   = "bootnodes-${var.deploy_version}"
      chain = var.chain_name
    }
  }
  spec {
    selector = {
      name = "${var.chain_name}-bootnodes-${var.deploy_version}-${count.index + local.offset}"
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
    load_balancer_ip        = google_compute_address.region_2nd[count.index].address
    external_traffic_policy = "Local"
  }
}

# output
output "bootnodes" {
  description = ""
  value       = local.bootnodes
}

output "bootnodes_dns" {
  description = ""
  value       = local.bootnodes_dns
}
