provider "google" {
  project = var.project
  region  = var.region
}

data "google_client_config" "default" {
}

data "google_container_cluster" "default" {
  name     = var.cluster
  location = var.region
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.default.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.default.master_auth[0].cluster_ca_certificate)
}

module "fullnode" {
  source = "./node"

  for_each      = var.chains
  chain_name    = each.key
  chainspec_url = each.value.chainspec
  bootnodes     = each.value.bootnodes
  base_image    = each.value.image
  start_cmd     = each.value.command
}

locals {
  api_config = jsonencode({
    "messengers": {for k, v in module.fullnode : k => ["ws://messenger:7004"]}
  })

  stat_config = jsonencode({
    "chain": {for k, v in module.fullnode : k => {}}
  })

  messenger_config = jsonencode({
    "chain": {for k, v in module.fullnode : k => {
      rpc = ["http://${v.service_name}:9933"]
      ws = ["ws://${v.service_name}:9944"]
      processors = ["node", "cache"]
    }}
  })

  etcd_txn = templatefile("${path.module}/template/txn.tpl", {
    api_config = local.api_config
    stat_config = local.stat_config
    messenger_config = local.messenger_config
    messenger_processor_config = file("${path.module}/template/processor.json")
    chains = [for k, v in module.fullnode : k]
    # how to escape ??
    api_config_escape = replace(local.api_config, "\"", "\\\"")
  })
}

# Interact with etcd service
resource "kubernetes_job" "defult" {
  metadata {
    name = "etcdctl"
  }
  spec {
    template {
      metadata {}
      spec {
        container {
          image   = "gcr.io/cloud-marketplace/google/etcd@sha256:9e77b8c32ae8a94c322f36f8d68aff4b0b5c7e2ef9d367daba499a7dee4d4faf"
          name    = "etcdctl"
          command = ["/bin/sh", "-c"]
          args = ["echo '${local.etcd_txn}' | etcdctl --endpoints=${var.etcd.hosts} --user=${var.etcd.username}:${var.etcd.password} txn"]
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
      }
    }
    # backoff_limit = 3
    ttl_seconds_after_finished = 100
  }
  wait_for_completion = true
  timeouts {
    create = "5m"
  }
}

output "txn" {
  description = "etcd txn script"
  value       = local.etcd_txn
}
