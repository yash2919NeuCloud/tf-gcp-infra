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
  name                     = var.webapp_subnet_name
  network                  = google_compute_network.my_vpc.id
  ip_cidr_range            = var.webapp_subnet_cidr
  region                   = var.region
  private_ip_google_access = true
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
  name        = "allow-webapp"
  network     = google_compute_network.my_vpc.id
  target_tags = ["allow-health-check", "http-server", "https-server", "lb-health-check"]
  allow {
    protocol = var.protocol
    ports    = [var.webapp_port]
  }

  # source_ranges = [var.source_ranges]
  source_ranges = [var.source_ranges_lb_1, var.source_ranges_lb_2]

}

resource "google_compute_firewall" "restrict_ssh" {
  name    = "restrict-ssh"
  network = google_compute_network.my_vpc.id

  allow {
    protocol = var.protocol
    ports    = [var.restrict_port]
  }


  source_ranges = [var.source_ranges]
}



resource "google_service_account" "service_account" {
  account_id   = "service-account-1"
  display_name = "Service Account"
}




resource "google_compute_managed_ssl_certificate" "lb_default" {
  name = "myservice-ssl-cert"

  managed {
    domains = [var.domains]
  }
  # lifecycle {
  #   prevent_destroy = true
  # }
}

resource "google_project_iam_binding" "logging_admin_binding" {
  project = var.project_id
  role    = "roles/logging.admin"

  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

resource "google_project_iam_binding" "monitoring_metric_writer_binding" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"

  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}
resource "google_project_iam_binding" "pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"

  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}

resource "google_project_iam_binding" "serviceAccountTokenCreator" {
  project = var.project_id
  role    = "roles/iam.serviceAccountTokenCreator"

  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}



resource "google_dns_record_set" "dns_record" {
  name         = var.dns_record
  type         = "A"
  ttl          = var.ttl
  managed_zone = var.managed_zone
  rrdatas      = [google_compute_global_address.default.address]
  depends_on   = [google_compute_global_address.default]
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


