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
  namespace     = var.namespace
}

locals {
  api_config = jsonencode({
    "messengers": {for k, v in module.fullnode : k => ["ws://gateway-messenger:7004"]}
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

  messenger_processor_config = file("${path.module}/template/processor.json")
}

# Interact with firestore
resource "google_firestore_document" "api" {
  project     = var.project
  collection  = var.firestore.collection
  document_id = "api"
  fields      = jsonencode({"config.json": {"stringValue": local.api_config}})
}

resource "google_firestore_document" "messenger" {
  project     = var.project
  collection  = var.firestore.collection
  document_id = "messenger"
  fields      = jsonencode(merge(
    {"config.json": {"stringValue": local.messenger_config}},
    {for k, v in module.fullnode : k => {stringValue=local.messenger_processor_config}}
  ))
}

resource "google_firestore_document" "stat" {
  project     = var.project
  collection  = var.firestore.collection
  document_id = "stat"
  fields      = jsonencode({"config.json": {"stringValue": local.stat_config}})
}

