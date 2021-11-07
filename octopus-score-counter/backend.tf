terraform {
  backend "gcs" {
    bucket  = "tf-state-octopus"
    prefix  = "terraform/state/octopus-score-counter"
  }
}
