terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

locals {
  credentials = jsondecode(file(var.gcp_credentials_file))
}

provider "google" {
  credentials = file(var.gcp_credentials_file)
  project     = local.credentials.project_id
  region      = var.region
}

resource "google_compute_instance" "default" {
  name         = "devops-instance"
  machine_type = "n2-standard-8"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "projects/ubuntu-os-cloud/global/images/family/ubuntu-2204-lts"
      size  = 100
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    ssh-keys = "ubuntu:${var.ssh_public_key}"
  }

  # 🔑 IMPORTANT: Add 'ssh' tag so firewall rule applies
  tags = ["ssh"]
}

# 🔐 Firewall rule to allow SSH from anywhere
resource "google_compute_firewall" "custom_allow_ssh" {
  name    = "custom-allow-ssh"  # <--- changed from default-allow-ssh
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh"]
}

output "instance_ip" {
  value = google_compute_instance.default.network_interface[0].access_config[0].nat_ip
}
