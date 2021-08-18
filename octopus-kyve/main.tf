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

module "kyve" {
  source = "./kyve"

  for_each         = var.kyve
  appchain_id      = each.value.appchain_id
  kyve_image       = each.value.kyve_image
  uploader_config  = "${path.module}/${each.value.kyve_files}/uploader-config.json"
  uploader_secret  = "${path.module}/${each.value.kyve_files}/uploader-key.json"
  validator_config = "${path.module}/${each.value.kyve_files}/validator-config.json"
  validator_secret = "${path.module}/${each.value.kyve_files}/validator-key.json"
}
