resource "kubernetes_config_map" "default" {
  metadata {
    name      = "relayer-config-map"
    namespace = var.appchain_id
  }
  data = {
    APPCHAIN_ID       = var.appchain_id
    APPCHAIN_ENDPOINT = var.appchain_endpoint
    NEAR_NODE_URL     = var.near_node_url
    NEAR_WALLET_URL   = var.near_wallet_url
    NEAR_HELPER_URL   = var.near_helper_url
    RELAY_CONTRACT_ID = var.relay_contract_id
  }
}

resource "kubernetes_secret" "default" {
  metadata {
    name      = "relayer-secret"
    namespace = var.appchain_id
  }
  data = {
    RELAYER_PRIVATE_KEY = var.relayer_private_key
  }
}

resource "kubernetes_stateful_set" "default" {
  metadata {
    name      = "${var.appchain_id}-relayer"
    namespace = var.appchain_id
  }
  spec {
    service_name           = "${var.appchain_id}-relayer"
    pod_management_policy  = "Parallel"
    replicas               = var.replicas
    revision_history_limit = 5
    selector {
      match_labels = {
        k8s-app = "${var.appchain_id}-relayer"
      }
    }
    template {
      metadata {
        labels = {
          k8s-app = "${var.appchain_id}-relayer"
        }
      }
      spec {
        init_container {
          name              = "${var.appchain_id}-init-db"
          image             = "busybox"
          image_pull_policy = "IfNotPresent"
          command           = ["touch", "/tmp/relayer.db"]
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
            name       = "${var.appchain_id}-relayer-data"
            mount_path = "/tmp"
          }
        }
        container {
          name              = "${var.appchain_id}-relayer"
          image             = var.relayer_image
          image_pull_policy = "IfNotPresent"
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
            name       = "${var.appchain_id}-relayer-data"
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
        name = "${var.appchain_id}-relayer-data"
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
