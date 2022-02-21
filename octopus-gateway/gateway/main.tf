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

# service_account
data "kubernetes_namespace" "default" {
  metadata {
    name = var.namespace
  }
}

resource "kubernetes_service_account" "default" {
  metadata {
    name = "octopus-gateway-ksa"
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

# gateway api
module "gateway_api" {
  source = "./api"

  namespace       = data.kubernetes_namespace.default.metadata.0.name
  gateway_api     = var.gateway_api
  postgresql      = var.postgresql
  service_account = kubernetes_service_account.default.metadata.0.name
}

# gateway router
module "gateway_router" {
  source = "./router"

  namespace      = data.kubernetes_namespace.default.metadata.0.name
  gateway_router = var.gateway_router
  kafka          = var.kafka
}
