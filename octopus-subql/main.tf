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

# subql (appchain)
module "subql" {
  source = "./subql"

  for_each            = var.subql
  appchain_id         = each.value.appchain_id
  appchain_endpoint   = each.value.appchain_endpoint
  gce_proxy_image     = each.value.gce_proxy_image
  gce_proxy_instances = each.value.gce_proxy_instances
  subql_node_image    = each.value.subql_node_image
  subql_query_image   = each.value.subql_query_image
  project             = var.project
  service_account     = var.service_account
  database            = var.database
}

# ingress (octopus-subql)
resource "kubernetes_namespace" "default" {
  metadata {
    labels = {
      name = "octopus-subql"
    }
    name = "octopus-subql"
  }
}

resource "google_compute_global_address" "default" {
  name  = "subql-global-address"
}

resource "google_compute_managed_ssl_certificate" "default" {
  name = "subql-testnet-octopus-network"
  managed {
    domains = var.subql_domains
  }
}

resource "kubernetes_service" "default" {
  for_each = module.subql

  metadata {
    name        = each.value.service_name
    namespace   = kubernetes_namespace.default.metadata.0.name
  }
  spec {
    type = "ExternalName"
    external_name = "${each.value.service_name}.default"
    # external_name = "${each.value.service_name}.${each.key}" #.svc.cluster.local
    port {
      port = each.value.service_port
    }
  }
}

resource "kubernetes_ingress" "default" {
  metadata {
    name        = "subql-ingress"
    namespace   = kubernetes_namespace.default.metadata.0.name
    annotations = {
      "kubernetes.io/ingress.global-static-ip-name" = google_compute_global_address.default.name
      "networking.gke.io/managed-certificates"      = google_compute_managed_ssl_certificate.default.name
      "kubernetes.io/ingress.class"                 = "gce"
      # "kubernetes.io/ingress.allow-http"            = false
    }
  }
  spec {
    rule {
      http {
        dynamic "path" {
          for_each = module.subql
          content {
            backend {
              service_name = path.value.service_name
              service_port = path.value.service_port
            }
            path = "/${path.key}/*"
          }
        }
      }
    }
  }
  depends_on = [kubernetes_service.default]
}
