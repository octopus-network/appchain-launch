terraform {
  backend "gcs" {
    bucket  = "tf-state-octopus"
    prefix  = "terraform/state/octopus-gateway/nodes"
  }
}
