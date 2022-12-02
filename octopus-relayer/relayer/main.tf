resource "kubernetes_config_map" "default" {
  metadata {
    name      = "${var.appchain_id}-relayer-config-map"
    namespace = var.namespace
  }
  data = {
    NODE_ENV                   = var.node_env
    APPCHAIN_ID                = var.appchain_id
    APPCHAIN_ENDPOINT          = var.appchain_endpoint
    RELAYER_ID                 = var.relayer_id
    NEAR_NODE_URL              = var.near_node_url
    NEAR_WALLET_URL            = var.near_wallet_url
    NEAR_HELPER_URL            = var.near_helper_url
    ANCHOR_CONTRACT_ID         = var.anchor_contract_id
    START_BLOCK_HEIGHT         = var.start_block_height
    UPDATE_STATE_MIN_INTERVAL  = var.update_state_min_interval
    APPCHAIN_SETTINGS          = var.APPCHAIN_SETTINGS
    CONTRACTS                  = var.CONTRACTS
    NEAR_SETTINGS              = var.NEAR_SETTINGS
  }
}

resource "kubernetes_secret" "default" {
  metadata {
    name      = "${var.appchain_id}-relayer-secret"
    namespace = var.namespace
  }
  data = {
    RELAYER_PRIVATE_KEY  = var.relayer_private_key
    RELAYER_NEAR_ACCOUNT = var.RELAYER_NEAR_ACCOUNT
  }
}

resource "kubernetes_stateful_set" "default" {
  metadata {
    name      = "${var.appchain_id}-relayer"
    namespace = var.namespace
    labels = {
      name  = "${var.appchain_id}-relayer"
      app   = "relayer"
      chain = var.appchain_id
    }
  }
  spec {
    service_name           = "${var.appchain_id}-relayer"
    pod_management_policy  = "Parallel"
    replicas               = var.replicas
    revision_history_limit = 5
    selector {
      match_labels = {
        name  = "${var.appchain_id}-relayer"
        app   = "relayer"
        chain = var.appchain_id
      }
    }
    template {
      metadata {
        labels = {
          name  = "${var.appchain_id}-relayer"
          app   = "relayer"
          chain = var.appchain_id
        }
      }
      spec {
        init_container {
          name              = "init-db"
          image             = "busybox"
          command           = ["touch", "/tmp/relayer.db"]
          volume_mount {
            name       = "relayer-data-volume"
            mount_path = "/tmp"
          }
        }
        container {
          name              = "relayer"
          image             = var.relayer_image
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
            name       = "relayer-data-volume"
            mount_path = "/usr/src/app/relayer.db"
            sub_path   = "relayer.db"
          }
          env_from {
            config_map_ref {
              name = kubernetes_config_map.default.metadata.0.name
            }
          }
          env_from {
            secret_ref {
              name = kubernetes_secret.default.metadata.0.name
            }
          }
        }
      }
    }
    volume_claim_template {
      metadata {
        name = "relayer-data-volume"
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
