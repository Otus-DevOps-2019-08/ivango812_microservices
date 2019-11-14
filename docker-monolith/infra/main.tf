provider "google" {
  version = "~>2.15"
  project = var.project
  region  = var.region
}

resource "google_compute_instance" "docker-host" {
  count = var.instances_count
  name = "docker-host-${count.index}"
  machine_type = var.machine_type
  zone = var.zone
  tags = ["docker-machines"]
  boot_disk {
    initialize_params {
      image = var.disk_image
    }
  }
  network_interface {
    network = "default"
    access_config {}
  }
  metadata = {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }
}

resource "google_compute_firewall" "firewall_docker" {
  name = "docker-machines"
  network = "default"
  allow {
    protocol = "tcp"
    ports = ["2376"]
  }
  source_ranges = ["0.0.0.0/0"]
}
