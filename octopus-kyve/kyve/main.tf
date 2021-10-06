
resource "kubernetes_config_map" "default" {
  metadata {
    name      = "${var.appchain_id}-kyve-config-map"
    namespace = var.namespace
  }
  data = {
    "uploader.config.json"  = file(var.uploader_config)
    "validator.config.json" = file(var.validator_config)
  }
}

resource "kubernetes_secret" "default" {
  metadata {
    name      = "${var.appchain_id}-kyve-secret"
    namespace = var.namespace
  }
  data = {
    "uploader.key.json"  = file(var.uploader_secret)
    "validator.key.json" = file(var.validator_secret)
  }
}

resource "kubernetes_deployment" "default" {
  metadata {
    name = "${var.appchain_id}-kyve"
    namespace = var.namespace
    labels = {
      name  = "${var.appchain_id}-kyve"
      app   = "kyve"
      chain = var.appchain_id
    }
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        name  = "${var.appchain_id}-kyve"
        app   = "kyve"
        chain = var.appchain_id
      }
    }
    template {
      metadata {
        labels = {
          name  = "${var.appchain_id}-kyve"
          app   = "kyve"
          chain = var.appchain_id
        }
      }
      spec {
        container {
          name    = "kyve-uploader"
          image   = var.kyve_image
          env {
            name  = "CONFIG"
            value = "config.json"
          }
          env {
            name  = "WALLET"
            value = "arweave.json"
          }
          env {
            name  = "SEND_STATISTICS"
            value = "true"
          }
          env {
            name  = "MAINTAINER"
            value = "julian@oct.network"
          }
          env {
            name  = "NAME"
            value = "${var.appchain_id}-kyve-uploader"
          }
          volume_mount {
            name       = "kyve-config-volume"
            mount_path = "/config.json"
            sub_path   = "uploader.config.json"
          }
          volume_mount {
            name       = "kyve-secret-volume"
            mount_path = "/arweave.json"
            sub_path   = "uploader.key.json"
            read_only  = true
          }
        }
        container {
          name  = "kyve-validator"
          image = var.kyve_image

          env {
            name  = "CONFIG"
            value = "config.json"
          }
          env {
            name  = "WALLET"
            value = "arweave.json"
          }
          env {
            name  = "SEND_STATISTICS"
            value = "true"
          }
          env {
            name  = "MAINTAINER"
            value = "julian@oct.network"
          }
          env {
            name  = "NAME"
            value = "${var.appchain_id}-kyve-validator"
          }
          volume_mount {
            name       = "kyve-config-volume"
            mount_path = "/config.json"
            sub_path   = "validator.config.json"
          }
          volume_mount {
            name       = "kyve-secret-volume"
            mount_path = "/arweave.json"
            sub_path   = "validator.key.json"
            read_only  = true
          }
        }
        volume {
          name = "kyve-config-volume"
          config_map {
            name = kubernetes_config_map.default.metadata.0.name
          }
        }
        volume {
          name = "kyve-secret-volume"
          secret {
            secret_name = kubernetes_secret.default.metadata.0.name
          }
        }
      }
    }
  }
}