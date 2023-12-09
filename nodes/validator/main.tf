resource "google_compute_address" "default" {
  count = var.nodes.replicas
  name  = "ip-${var.chain_name}-validator-${count.index}"
}

data "google_dns_managed_zone" "default" {
  name = var.dns_zone
}

resource "google_dns_record_set" "default" {
  count        = var.nodes.replicas
  name         = "validator-${count.index}.${var.chain_name}.${data.google_dns_managed_zone.default.dns_name}"
  managed_zone = data.google_dns_managed_zone.default.name
  type         = "A"
  ttl          = 300
  rrdatas = [google_compute_address.default.*.address[count.index]]
}

locals {
  persistent_peers = [
    for idx, addr in google_compute_address.default.*.address :
    "${var.keys[idx]["node_id"]}@${addr}:26656"
  ]

  persistent_peers_dns = [
    for idx, addr in google_compute_address.default.*.address:
    "${var.keys[idx]["node_id"]}@validator-${idx}.${var.chain_name}.${trimsuffix(data.google_dns_managed_zone.default.dns_name, ".")}:26656"
  ]

  endpoints_options         = flatten([for srv, cfg in var.nodes.endpoints : cfg.options])
  endpoints_container_ports = flatten([for srv, cfg in var.nodes.endpoints : cfg.ports])
  endpoints_service_ports = merge([
    for srv, cfg in var.nodes.endpoints :
    cfg.expose == true && srv != "p2p" ? {
      for idx, port in cfg.ports :
      length(cfg.ports) > 1 ? "${srv}_${idx}" : srv => port
      # "${srv}_${idx}" => port
    } : {}
  ]...)
}

resource "kubernetes_config_map" "default" {
  metadata {
    name      = "${var.chain_name}-validator-config-map"
    namespace = var.namespace
  }
  data = {
    "init.sh" = file("${path.module}/init.sh")
  }
}

resource "kubernetes_secret" "default" {
  metadata {
    name      = "${var.chain_name}-validator-secret"
    namespace = var.namespace
  }
  data = merge([
    for idx, key in var.keys : {
      for k, v in key :
      "${idx}-${k}" => v
    }
  ]...)
}

resource "kubernetes_stateful_set" "default" {
  metadata {
    name      = "${var.chain_name}-validator"
    namespace = var.namespace
    labels = {
      name  = "${var.chain_name}-validator"
      app   = "validator"
      chain = var.chain_name
    }
  }
  spec {
    service_name           = "${var.chain_name}-validator"
    pod_management_policy  = "Parallel"
    replicas               = var.nodes.replicas
    revision_history_limit = 5
    selector {
      match_labels = {
        name  = "${var.chain_name}-validator"
        app   = "validator"
        chain = var.chain_name
      }
    }
    template {
      metadata {
        labels = {
          name  = "${var.chain_name}-validator"
          app   = "validator"
          chain = var.chain_name
        }
      }
      spec {
        container {
          name    = "validator"
          image   = var.nodes.image
          command = ["cosmovisor"]
          args = concat([
            "run",
            "start",
            "--home",
            "/data",
            "--log_format",
            "json"
          ], local.endpoints_options)
          dynamic "port" {
            for_each = local.endpoints_container_ports
            content {
              container_port = port.value
            }
          }
          resources {
            limits = {
              cpu    = var.nodes.resources.cpu_limits
              memory = var.nodes.resources.memory_limits
            }
            requests = {
              cpu    = var.nodes.resources.cpu_requests
              memory = var.nodes.resources.memory_requests
            }
          }
          volume_mount {
            name       = "validator-data-volume"
            mount_path = "/data"
          }
          # readiness_probe {
          #   http_get {
          #     path = "/health"
          #     port = 26657
          #   }
          #   initial_delay_seconds = 10
          #   timeout_seconds       = 1
          # }
          # liveness_probe {
          #   http_get {
          #     path = "/health"
          #     port = 26657
          #   }
          #   initial_delay_seconds = 10
          #   timeout_seconds       = 1
          # }
        }
        init_container {
          name  = "init-configuration"
          image = var.nodes.image
          command = [
            "/init.sh",
            var.nodes.command,
            var.nodes.moniker,
            var.chain_id,
            "/data",
            var.nodes.keyname,
            var.nodes.keyring,
            join(",", local.persistent_peers_dns),
            var.ibc_token_denom,
            var.enable_gas
          ]
          volume_mount {
            name       = "validator-data-volume"
            mount_path = "/data"
          }
          volume_mount {
            name       = "validator-config-volume"
            mount_path = "/init.sh"
            sub_path   = "init.sh"
          }
          volume_mount {
            name       = "validator-secret-volume"
            mount_path = "/keys" # 0-mnemonic 0-node_key ...
          }
        }
        init_container {
          name  = "download-genesis"
          image = "curlimages/curl"
          args = [
            "-L",
            "-o",
            "/data/config/genesis.json",
            var.nodes.genesis
          ]
          volume_mount {
            name       = "validator-data-volume"
            mount_path = "/data"
          }
          security_context {
            run_as_user = 0
          }
        }
        volume {
          name = "validator-config-volume"
          config_map {
            name         = kubernetes_config_map.default.metadata.0.name
            default_mode = "0555"
          }
        }
        volume {
          name = "validator-secret-volume"
          secret {
            secret_name = kubernetes_secret.default.metadata.0.name
          }
        }
        termination_grace_period_seconds = 300
      }
    }
    volume_claim_template {
      metadata {
        name      = "validator-data-volume"
        namespace = var.namespace
      }
      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = var.nodes.resources.volume_type
        resources {
          requests = {
            storage = var.nodes.resources.volume_size
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
  count = var.nodes.replicas
  metadata {
    name      = "${var.chain_name}-validator-${count.index}"
    namespace = var.namespace
    labels = {
      name  = "${var.chain_name}-validator-${count.index}"
      app   = "validator"
      chain = var.chain_name
    }
  }
  spec {
    selector = {
      "statefulset.kubernetes.io/pod-name" = "${var.chain_name}-validator-${count.index}"
    }
    session_affinity = "ClientIP"
    port {
      name        = "p2p"
      protocol    = "TCP"
      port        = var.nodes.endpoints["p2p"].ports[0]
      target_port = var.nodes.endpoints["p2p"].ports[0]
    }
    type                    = "LoadBalancer"
    load_balancer_ip        = google_compute_address.default[count.index].address
    external_traffic_policy = "Local"
  }
}
