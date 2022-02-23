
locals {
  keys_octoup = merge([
    for idx, keys in var.keys_octoup: {
      for k, v in keys:
        "${idx}-${k}" => v
    }
  ]...)
}

resource "kubernetes_secret" "default" {
  metadata {
    name      = "${var.chain_name}-validators-job-secret-${var.deploy_version}"
    namespace = var.namespace
  }
  data       = local.keys_octoup
  depends_on = [var.module_depends_on]
}

resource "kubernetes_config_map" "default" {
  metadata {
    name      = "${var.chain_name}-validators-job-config-map-${var.deploy_version}"
    namespace = var.namespace
  }
  data = {
    "run.sh" = file("${path.module}/run.sh")
  }
  depends_on = [var.module_depends_on]
}

resource "kubernetes_job" "default" {
  metadata {
    name      = "${var.chain_name}-validators-add-keys-${var.deploy_version}"
    namespace = var.namespace
    labels = {
      name  = "${var.chain_name}-validators-add-keys-${var.deploy_version}"
      app   = "validators-${var.deploy_version}"
      chain = var.chain_name
    }
  }
  spec {
    manual_selector = true
    selector {
      match_labels = {
        name  = "${var.chain_name}-validators-add-keys-${var.deploy_version}"
        app   = "validators-${var.deploy_version}"
        chain = var.chain_name
      }
    }
    template {
      metadata {
        labels = {
          name  = "${var.chain_name}-validators-add-keys-${var.deploy_version}"
          app   = "validators-${var.deploy_version}"
          chain = var.chain_name
        }
      }
      spec {
        container {
          image   = "radial/busyboxplus:curl"
          name    = "add-keys"
          command = ["/chain/run.sh", "${var.chain_name}-validators-${var.deploy_version}"]
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
            name       = "validators-job-config-volume-${var.deploy_version}"
            mount_path = "/chain/run.sh"
            sub_path = "run.sh"
          }
          volume_mount {
            name       = "validators-job-secret-volume-${var.deploy_version}"
            mount_path = "/chain/keys"
          }
          security_context {
            allow_privilege_escalation = false
            capabilities {
              add  = []
              drop = ["NET_RAW"]
            }
          }
        }
        volume {
          name = "validators-job-config-volume-${var.deploy_version}"
          config_map {
            name = kubernetes_config_map.default.metadata.0.name
            default_mode = "0555"
          }
        }
        volume {
          name = "validators-job-secret-volume-${var.deploy_version}"
          secret {
            secret_name = kubernetes_secret.default.metadata.0.name
          }
        }
        restart_policy = "Never"
      }
    }
    ttl_seconds_after_finished = 100
  }
  wait_for_completion = true
  timeouts {
    create = "5m"
  }
  depends_on = [var.module_depends_on]
}


# Substrate nodes require a restart after inserting a GRANDPA key
resource "kubernetes_role" "restart" {
  metadata {
    name      = "${var.chain_name}-validators-restart-role-${var.deploy_version}"
    namespace = var.namespace
  }
  rule {
    api_groups     = ["apps"]
    resources      = ["statefulsets"]
    resource_names = ["${var.chain_name}-validators-${var.deploy_version}"]
    verbs          = ["get", "patch"]
  }
  depends_on = [var.module_depends_on]
}

resource "kubernetes_role_binding" "restart" {
  metadata {
    name      = "${var.chain_name}-validators-restart-role-binding-${var.deploy_version}"
    namespace = var.namespace
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.restart.metadata.0.name
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
    namespace = var.namespace
  }
}

resource "kubernetes_job" "restart" {
  metadata {
    name      = "${var.chain_name}-validators-restart-nodes-${var.deploy_version}"
    namespace = var.namespace
    labels = {
      name  = "${var.chain_name}-validators-restart-nodes-${var.deploy_version}"
      app   = "validators-${var.deploy_version}"
      chain = var.chain_name
    }
  }
  spec {
    manual_selector = true
    selector {
      match_labels = {
        name  = "${var.chain_name}-validators-restart-nodes-${var.deploy_version}"
        app   = "validators-${var.deploy_version}"
        chain = var.chain_name
      }
    }
    template {
      metadata {
        labels = {
          name  = "${var.chain_name}-validators-restart-nodes-${var.deploy_version}"
          app   = "validators-${var.deploy_version}"
          chain = var.chain_name
        }
      }
      spec {
        container {
          image   = "bitnami/kubectl"
          name    = "restart-sts"
          command = ["kubectl", "rollout", "restart", "statefulsets/${var.chain_name}-validators-${var.deploy_version}"]
          # kubectl scale statefulset ${var.chain_name}-validators --replicas=0
          # kubectl scale statefulset ${var.chain_name}-validators --replicas=4
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
          security_context {
            allow_privilege_escalation = false
            capabilities {
              add  = []
              drop = ["NET_RAW"]
            }
          }
        }
        restart_policy = "Never"
        service_account_name = kubernetes_role_binding.restart.subject.0.name
      }
    }
    ttl_seconds_after_finished = 100
  }
  wait_for_completion = true
  timeouts {
    create = "5m"
  }
  depends_on = [kubernetes_job.default]
}
