provider "google" {
  version = "~>2.15"
  project = var.project
  region  = var.region
}

resource "google_compute_instance" "docker-host" {
  count        = var.instances_count
  name         = "docker-host-${count.index}"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["docker-machines"]
  boot_disk {
    initialize_params {
      image = var.disk_image
    }
  }
  network_interface {
    network = "default"
    access_config {
    }
  }
  metadata = {
    ssh-keys = "appuser:${file(var.public_key_path)}"
  }
  // connection {
  //   type  = "ssh"
  //   host  = self.network_interface[0].access_config[0].nat_ip
  //   user  = "appuser"
  //   agent = false
  //   private_key = file(var.private_key_path)
  // }
  // provisioner "file" {
  //   source      = "${path.module}/files/mongod.conf"
  //   destination = var.enable_provisioner == true ? "/tmp/mongod.conf": "/dev/null"
  // }
  // provisioner "remote-exec" {
  //   script = var.enable_provisioner == true ? "${path.module}/files/deploy.sh": ""
  // }
  // provisioner "local-exec" {
  //   when = "destroy"
  //   command = "ssh-keygen -R ${self.network_interface[0].access_config[0].nat_ip}"
  // }  
}

resource "google_compute_firewall" "firewall_docker" {
  name    = "docker-machines"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["2376"]
  }
  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "firewall_reddit" {
  name    = "reddit-http"
  network = "default"
  allow {
    protocol = "tcp"
    ports    = ["9292"]
  }
  source_ranges = ["0.0.0.0/0"]
}
