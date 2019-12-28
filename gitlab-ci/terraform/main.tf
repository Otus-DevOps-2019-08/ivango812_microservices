terraform {
  required_version = "0.12.15"
}

provider "google" {
  version = "2.15"
  project = "docker-258721"
  region = "europe-west-1"
}

resource "google_compute_instance" "gitlab" {
  name = "gitlab-ce"
  machine_type = "n1-standard-1"
  zone = "europe-west1-b"
  tags = ["gitlab"]
  boot_disk {
    initialize_params {
      image = "ubuntu-1604-lts"
      size = 100
    }
  }
  
  network_interface {
    network = "default"
    access_config {}
  }
}

resource "google_compute_firewall" "firewall_gitlab" {
  name = "gitlab-allow"
  network = "default"
  allow {
    protocol = "tcp"
    ports = ["22", "80", "443"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["gitlab"]
}

output "gitlab_external_ip" {
  value = google_compute_instance.gitlab.network_interface[0].access_config[0].nat_ip
}
