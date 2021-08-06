
locals {
  dir_key_list_map = flatten([
    for i, d in var.dirs: [
      for k in var.keys: {
        key = "${i}-${k}"
        val = file("${d}/${k}")
      }
    ]
  ])

  dir_key_map = {
    for item in local.dir_key_list_map: item.key => item.val
  }
}

resource "kubernetes_secret" "default" {
  metadata {
    name = "${var.chain_name}-job-secret"
  }
  data = local.dir_key_map
}

resource "kubernetes_config_map" "default" {
  metadata {
    name = "${var.chain_name}-job-config-map"
  }
  data = {
    "run.sh" = file("${path.module}/run.sh")
  }
}

resource "kubernetes_job" "default" {
  metadata {
    name = "${var.chain_name}-add-keys"
  }
  spec {
    template {
      metadata {}
      spec {
        container {
          image   = "radial/busyboxplus:curl"
          name    = "${var.chain_name}-add-keys"
          command = ["/chain/run.sh", var.chain_name]
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
            name       = "${var.chain_name}-job-config-volume"
            mount_path = "/chain/run.sh"
            sub_path = "run.sh"
          }
          volume_mount {
            name       = "${var.chain_name}-job-secret-volume"
            mount_path = "/chain/keys"
          }
        }
        volume {
          name = "${var.chain_name}-job-config-volume"
          config_map {
            name = "${var.chain_name}-job-config-map"
            default_mode = "0555"
          }
        }
        volume {
          name = "${var.chain_name}-job-secret-volume"
          secret {
            secret_name = "${var.chain_name}-job-secret"
          }
        }
        restart_policy = "Never"
      }
    }
    # backoff_limit = 3
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
    name = "${var.chain_name}-restart-role"
  }
  rule {
    api_groups     = ["apps"]
    resources      = ["statefulsets"]
    resource_names = [var.chain_name]
    verbs          = ["get", "patch"]
  }
}

resource "kubernetes_role_binding" "restart" {
  metadata {
    name = "${var.chain_name}-restart-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = "${var.chain_name}-restart-role"
  }
  subject {
    kind      = "ServiceAccount"
    name      = "default"
  }
}

resource "kubernetes_job" "restart" {
  metadata {
    name = "${var.chain_name}-restart-nodes"
  }
  spec {
    template {
      metadata {}
      spec {
        container {
          image   = "bitnami/kubectl"
          name    = "${var.chain_name}-restart-nodes"
          command = ["kubectl", "rollout", "restart", "statefulsets/${var.chain_name}"]
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
        }
        restart_policy = "Never"
        service_account_name = "default"
      }
    }
    # backoff_limit = 3
    ttl_seconds_after_finished = 100
  }
  wait_for_completion = true
  timeouts {
    create = "5m"
  }
  depends_on = [kubernetes_job.default]
}

# resource "null_resource" "default" {
#   depends_on = [kubernetes_job.default]
#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]
#     command = "kubectl rollout restart sts ${var.chain_name}"
#   }
# }