provider "google" {
  //credentials = file(var.credentials_file)
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "my_vpc" {
  name                            = var.vpc_name
  auto_create_subnetworks         = var.network_auto_create_subnets
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "webapp_subnet" {
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

resource "google_project_service" "service_networking" {
  service = "servicenetworking.googleapis.com"
}
resource "google_compute_instance" "instance-1" {
  machine_type = var.machine_type
  name         = var.instance_name
  tags         = var.tags
  zone         = var.zone
  metadata_startup_script = templatefile("./startup.tpl", {
    db_host     = google_sql_database_instance.example_instance.first_ip_address,
    db_password = random_password.webapp_db_password.result,
    db_database = google_sql_database.webapp_db.name,
    db_user     = google_sql_user.webapp_db_user.name
  })

  depends_on = [
    google_sql_database_instance.example_instance
  ]

  boot_disk {
    device_name = "Vm1"

    initialize_params {
      image = var.boot_disk_image
      size  = var.boot_disk_size
      type  = var.boot_disk_type
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.webapp_subnet.id
    access_config {
      network_tier = "PREMIUM"
    }

  }
}



resource "google_compute_global_address" "private_ip_address" {
  name          = var.global_address_name
  purpose       = var.global_address_purpose
  address_type  = var.global_address_type
  prefix_length = var.global_address_prefix_length
  network       = google_compute_network.my_vpc.id

}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.my_vpc.id
  service                 = var.service_name
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}

resource "google_sql_database_instance" "example_instance" {
  name             = var.sql_instance_name
  region           = var.region
  database_version = var.database_version

  deletion_protection = false

  depends_on = [
    google_service_networking_connection.private_vpc_connection
  ]

  # Set the custom VPC network
  settings {
    availability_type = var.availability_type
    disk_type         = var.disk_type
    disk_size         = var.disk_size_gb
    tier              = var.sql_machine_type
    activation_policy = "ALWAYS"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.my_vpc.id
    }
    backup_configuration {
      binary_log_enabled = true
      enabled            = true
    }
  }
}

resource "google_sql_database" "webapp_db" {
  name      = var.database_name
  instance  = google_sql_database_instance.example_instance.name
  charset   = "utf8"
  collation = "utf8_general_ci"
}

resource "random_password" "webapp_db_password" {
  length  = var.database_user_password_length
  special = true
}
resource "google_sql_user" "webapp_db_user" {
  name     = var.database_user_name
  instance = google_sql_database_instance.example_instance.name
  password = random_password.webapp_db_password.result

}
