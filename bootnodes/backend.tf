terraform {
  backend "gcs" {
    bucket  = "tf-state-octopus"
    prefix  = "terraform/state/bootnodes"
  }
}
