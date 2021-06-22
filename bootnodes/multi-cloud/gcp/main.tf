
provider "google" {
  project = var.project
  region  = var.region
  zone    = var.availability_zones[0]
}

data "google_compute_image" "ubuntu" {
  count   = var.create ? 1 : 0
  family  = "ubuntu-minimal-2004-lts"
  project = "ubuntu-os-cloud"
}

resource "google_compute_address" "default" {
  count = var.bind_eip && var.create ? var.instance_count : 0
  name  = "ip-${var.id}-${count.index}"
}

resource "google_compute_instance" "instance" {
  count        = var.create ? var.instance_count : 0
  name         = "vm-${var.id}-${count.index}"
  machine_type = var.instance_type
  zone         = var.availability_zones[0]

  metadata = {
    ssh-keys = "ubuntu:${file(var.public_key_file)}"
  }

  boot_disk {
    auto_delete = true
    initialize_params {
      size  = var.volume_size
      type  = var.volume_type
      image = data.google_compute_image.ubuntu[0].self_link
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = var.bind_eip ? google_compute_address.default[count.index].address : null
    }
  }
}

resource "google_compute_firewall" "default" {
  name    = "fw-${var.id}-9933-9944-30333"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["9933", "9944", "30333"]
  }
}
