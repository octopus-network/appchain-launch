locals {
  name = replace("${var.chain_id_1}-${var.chain_id_2}", "_", "-")
}

resource "kubernetes_config_map" "default" {
  metadata {
    name      = "${local.name}-hermes-config-map"
    namespace = var.namespace
  }
  data = {
    "init.sh" = file("${path.module}/init.sh")
    # 20230203 Temporarily modify config.toml to enable telemetry
    "config.toml" = file("${path.module}/config.toml")
  }
}

resource "kubernetes_secret" "default" {
  metadata {
    name      = "${local.name}-hermes-secret"
    namespace = var.namespace
  }
  data = {
    ic_credential = var.ic_credential
    credential_1  = var.credential_1
    credential_2  = var.credential_2
  }
}

resource "kubernetes_stateful_set" "default" {
  metadata {
    name      = "${local.name}-hermes"
    namespace = var.namespace
    labels = {
      name  = "${local.name}-hermes"
      app   = "hermes"
      chain = local.name
    }
  }
  spec {
    service_name           = "${local.name}-hermes"
    pod_management_policy  = "Parallel"
    replicas               = 1
    revision_history_limit = 5
    selector {
      match_labels = {
        name  = "${local.name}-hermes"
        app   = "hermes"
        chain = local.name
      }
    }
    template {
      metadata {
        labels = {
          name  = "${local.name}-hermes"
          app   = "hermes"
          chain = local.name
          annotations = {
            "prometheus.io/scrape" = "true"
            "prometheus.io/scheme" = "http"
            "prometheus.io/path"   = "/metrics"
            "prometheus.io/port"   = "3001"
          }
        }
      }
      spec {
        container {
          name  = "hermes"
          image = var.image
          # command = ["hermes"]
          args = ["start"]
          port {
            container_port = 3001
          }
          dynamic "env" {
            for_each = var.rust_log == "" ? [] : [1]
            content {
              name  = "RUST_LOG"
              value = var.rust_log
            }
          }
          env {
            name  = "VIEWSTATE_NEAR_ENDPOINT"
            value = var.viewstate_near_endpoint
          }
          env {
            name  = "IC_ENDPOINT"
            value = var.ic_endpoint
          }
          env {
            name  = "CANISTER_ID"
            value = var.canister_id
          }
          env {
            name  = "CANISTER_PEM"
            value = var.canister_pem
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
            name       = "hermes-data-volume"
            mount_path = "/home/hermes/.hermes/keys"
          }
          volume_mount {
            name       = "hermes-secret-volume"
            mount_path = "/home/hermes/.hermes/keys/ic.pem"
            sub_path   = "ic_credential"
          }
          # 20230203 Temporarily modify config.toml to enable telemetry
          volume_mount {
            name       = "hermes-config-volume"
            mount_path = "/home/hermes/.hermes/config.toml"
            sub_path   = "config.toml"
          }
        }
        init_container {
          name  = "init"
          image = var.image
          command = [
            "/init.sh",
            var.chain_id_1,
            "/keys/credential_1",
            var.chain_id_2,
            "/keys/credential_2"
          ]
          volume_mount {
            name       = "hermes-data-volume"
            mount_path = "/home/hermes/.hermes/keys"
          }
          volume_mount {
            name       = "hermes-config-volume"
            mount_path = "/init.sh"
            sub_path   = "init.sh"
          }
          volume_mount {
            name       = "hermes-secret-volume"
            mount_path = "/keys"
          }
        }
        volume {
          name = "hermes-config-volume"
          config_map {
            name         = kubernetes_config_map.default.metadata.0.name
            default_mode = "0555"
          }
        }
        volume {
          name = "hermes-secret-volume"
          secret {
            secret_name = kubernetes_secret.default.metadata.0.name
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
        name      = "hermes-data-volume"
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
  lifecycle {
    ignore_changes = [
      spec[0].template[0].spec[0].container[0].resources
    ]
  }
}
