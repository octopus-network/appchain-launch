
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
    # backoff_limit           = 3
  }
  wait_for_completion = true
  timeouts {
    create = "5m"
    update = "5m"
  }
  depends_on = [var.module_depends_on]
}

resource "null_resource" "default" {
  depends_on = [kubernetes_job.default]
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = "kubectl rollout restart sts ${var.chain_name}"
  }
}
