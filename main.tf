provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project_id
  region      = var.region
}

resource "google_compute_network" "my_vpc" {
  name                            = var.vpc_name
  auto_create_subnetworks         = var.network_auto_create_subnets
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "webapp" {
  name          = var.webapp_subnet_name
  network       = google_compute_network.my_vpc.id
  ip_cidr_range = var.webapp_subnet_cidr
  region        = var.region
}

resource "google_compute_subnetwork" "db" {
  name          = var.db_subnet_name
  network       = google_compute_network.my_vpc.id
  ip_cidr_range = var.db_subnet_cidr
  region        = var.region
}

resource "google_compute_route" "default_route" {
  name             = var.default_route_name
  network          = google_compute_network.my_vpc.id
  dest_range       = var.default_route_dest_range
  next_hop_gateway = var.next_hop_gateway
}

# adding port 3000 to the firewall
resource "google_compute_firewall" "allow_webapp" {
  name    = "allow-webapp"
  network = google_compute_network.my_vpc.id

  allow {
    protocol = var.protocol
    ports    = [var.webapp_port]
  }

  source_ranges = [var.source_ranges]
}

resource "google_compute_firewall" "restrict_ssh" {
  name    = "restrict-ssh"
  network = google_compute_network.my_vpc.id

  deny {
    protocol = var.protocol
    ports    = [var.restrict_port]
  }

  source_ranges = [var.source_ranges]
}
resource "google_compute_instance" "instance-1" {
  machine_type = var.machine_type
  name         = var.instance_name
  tags         = var.tags
  zone         = var.zone
  boot_disk {
    device_name = "Vm1"

    initialize_params {
      image = var.boot_disk_image
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.webapp.id
    access_config {
      network_tier = "PREMIUM"
    }

  }
}
