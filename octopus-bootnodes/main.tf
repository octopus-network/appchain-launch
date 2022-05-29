provider "google" {
  project = var.project
  region  = var.region
}

provider "google" {
  project = var.project
  region  = var.region_2nd
  alias   = "gcp-2nd"
}

data "google_client_config" "default" {
}

data "google_client_config" "region_2nd" {
  provider = google.gcp-2nd
}

data "google_container_cluster" "default" {
  name     = var.cluster
  location = var.region
}

data "google_container_cluster" "region_2nd" {
  name     = var.cluster_2nd
  location = var.region_2nd
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.default.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.default.master_auth[0].cluster_ca_certificate)
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.region_2nd.endpoint}"
  token                  = data.google_client_config.region_2nd.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.region_2nd.master_auth[0].cluster_ca_certificate)
  alias                  = "gke-2nd"
}

# bootnodes
module "bootnodes" {
  source    = "./bootnodes"
  providers = {
    google.gcp-2nd     = google.gcp-2nd
    kubernetes.gke-2nd = kubernetes.gke-2nd
  }

  chain_name     = var.chain_name
  chain_spec     = var.chain_spec
  base_image     = var.base_image
  start_cmd      = var.start_cmd
  telemetry_url  = var.telemetry_url
  bootnodes      = var.bootnodes
  keys_octoup    = var.keys_octoup_node
  deploy_version = var.deploy_version
  dns_zone       = var.dns_zone

  namespace       = var.namespace
  replicas        = var.node_count
  cpu_requests    = var.cpu_requests
  cpu_limits      = var.cpu_limits
  memory_requests = var.memory_requests
  memory_limits   = var.memory_limits
  volume_type     = var.volume_type
  volume_size     = var.volume_size
}

# validators
module "validators" {
  source = "./validators"

  chain_name     = var.chain_name
  chain_spec     = var.chain_spec
  base_image     = var.base_image
  start_cmd      = var.start_cmd
  telemetry_url  = var.telemetry_url
  keys_octoup    = var.keys_octoup_session
  deploy_version = var.deploy_version

  namespace       = var.namespace
  replicas        = var.node_count
  cpu_requests    = var.cpu_requests
  cpu_limits      = var.cpu_limits
  memory_requests = var.memory_requests
  memory_limits   = var.memory_limits
  volume_type     = var.volume_type
  volume_size     = var.volume_size
}


output "bootnodes" {
  description = ""
  value       = module.bootnodes.bootnodes
}

output "bootnodes_dns" {
  description = ""
  value       = module.bootnodes.bootnodes_dns
}