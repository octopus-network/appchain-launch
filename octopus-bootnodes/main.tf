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

# bootnodes
module "bootnodes" {
  source = "./bootnodes"

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
  rust_log        = var.rust_log
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
  rust_log        = var.rust_log
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