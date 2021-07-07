
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

resource "kubernetes_pod" "default" {
  metadata {
    name = "${var.chain_name}-add-keys"
  }
  spec {
    container {
      image   = "radial/busyboxplus:curl"
      name    = "${var.chain_name}-add-keys"
      command = ["/chain/run.sh", var.chain_name]
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
  depends_on = [var.module_depends_on]
}
