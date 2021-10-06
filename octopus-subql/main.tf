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

data "kubernetes_namespace" "default" {
  metadata {
    name = var.namespace
  }
}

# subql
resource "kubernetes_service_account" "default" {
  metadata {
    name = "subql-ksa"
    namespace = data.kubernetes_namespace.default.metadata.0.name
    annotations = {
      "iam.gke.io/gcp-service-account" = var.service_account
    }
  }
}

data "google_service_account" "default" {
  account_id = var.service_account
}

resource "google_service_account_iam_member" "default" {
  service_account_id = data.google_service_account.default.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project}.svc.id.goog[${data.kubernetes_namespace.default.metadata.0.name}/${kubernetes_service_account.default.metadata.0.name}]"
}

module "subql" {
  source = "./subql"

  for_each            = var.subql
  namespace           = data.kubernetes_namespace.default.metadata.0.name
  appchain_id         = each.value.appchain_id
  appchain_endpoint   = each.value.appchain_endpoint
  gce_proxy_image     = each.value.gce_proxy_image
  gce_proxy_instances = each.value.gce_proxy_instances
  subql_node_image    = each.value.subql_node_image
  subql_query_image   = each.value.subql_query_image
  database            = var.database
  service_account     = kubernetes_service_account.default.metadata.0.name
}

# ingress
resource "google_compute_global_address" "default" {
  name  = "subql-global-address"
}

resource "google_compute_managed_ssl_certificate" "default" {
  name = "subql-testnet-octopus-network"
  managed {
    domains = var.subql_domains
  }
}

resource "kubernetes_ingress" "default" {
  metadata {
    name        = "subql-ingress"
    namespace   = data.kubernetes_namespace.default.metadata.0.name
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
            path = "/${path.key}"
          }
        }
      }
    }
  }
}
