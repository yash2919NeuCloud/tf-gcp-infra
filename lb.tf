
# Regional Compute Instance Template
resource "google_compute_region_instance_template" "template" {
  name         = "instance-1"
  machine_type = var.machine_type
  region       = var.region
  disk {
    source_image = var.boot_disk_image
    auto_delete  = true
    boot         = true
    # type         = "pd-standard"
    disk_size_gb = var.boot_disk_size
    disk_encryption_key {
      kms_key_self_link = google_kms_crypto_key.vm_key.id
    }
  }

  network_interface {
    network    = google_compute_network.my_vpc.id
    subnetwork = google_compute_subnetwork.webapp_subnet.id
    access_config {}

  }
  service_account {
    email  = google_service_account.service_account.email
    scopes = ["cloud-platform"]
  }
  depends_on = [
    google_sql_database_instance.example_instance
  ]

  metadata_startup_script = templatefile("./startup.tpl", {
    db_host     = google_sql_database_instance.example_instance.first_ip_address,
    db_password = random_password.webapp_db_password.result,
    db_database = google_sql_database.webapp_db.name,
    db_user     = google_sql_user.webapp_db_user.name
  })
  tags = ["allow-health-check", "http-server", "https-server", "lb-health-check"]
}

# Compute Health Check
resource "google_compute_health_check" "health_check" {
  name               = "web-health-check"
  check_interval_sec = var.check_interval_sec
  timeout_sec        = var.timeout_sec
  # healthy_threshold   = var.healthy_threshold
  # unhealthy_threshold = var.unhealthy_threshold
  http_health_check {
    port               = var.webapp_port_int
    request_path       = var.request_path
    port_specification = "USE_FIXED_PORT"
    proxy_header       = "NONE"
  }

}


resource "google_compute_region_autoscaler" "autoscaler" {
  name   = "web-autoscaler"
  target = google_compute_region_instance_group_manager.manager.id
  region = var.region
  autoscaling_policy {
    min_replicas    = var.min_replicas
    max_replicas    = var.max_replicas
    cooldown_period = var.cooldown_period
    cpu_utilization {
      target = var.cpu_utilization
    }
  }
}


resource "google_compute_region_instance_group_manager" "manager" {
  name               = "web-instance-group-manager"
  base_instance_name = "web-instance"
  region             = var.region
  target_size        = 3


  version {
    instance_template = google_compute_region_instance_template.template.id
    name              = "primary"
  }
  named_port {
    name = "http"
    port = var.webapp_port_int
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.health_check.id
    initial_delay_sec = 250
  }
}

# resource "google_compute_firewall" "allow_lb" {
#   name        = "allow-lb"
#   network     = google_compute_network.my_vpc.id
#   direction   = "INGRESS"
#   priority    = 1000
#   target_tags = ["allow-health-check", "http-server", "https-server", "lb-health-check"]

#   allow {
#     protocol = "tcp"
#     ports    = ["443", "3000"]
#   }

#   source_ranges = [var.source_ranges]
#   # source_ranges = [google_compute_global_address.default.address]
#   # depends_on    = [google_compute_global_address.default]
# }

resource "google_compute_global_address" "default" {
  name         = "address-name"
  address_type = "EXTERNAL"

}

resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name                  = "web-forwarding-rule"
  target                = google_compute_target_https_proxy.proxy.id
  port_range            = var.https_port
  ip_address            = google_compute_global_address.default.address
  load_balancing_scheme = "EXTERNAL"
  ip_protocol           = "TCP"
}


resource "google_compute_url_map" "url_map" {
  name            = "web-url-map"
  default_service = google_compute_backend_service.backend_service.id
}

resource "google_compute_backend_service" "backend_service" {
  name          = "web-backend-service"
  protocol      = "HTTP"
  port_name     = "http"
  timeout_sec   = var.backend_service_timeout_seconds
  health_checks = [google_compute_health_check.health_check.id]
  backend {
    group           = google_compute_region_instance_group_manager.manager.instance_group
    capacity_scaler = 1.0
    balancing_mode  = "UTILIZATION"

  }
}

resource "google_compute_target_https_proxy" "proxy" {
  name    = "web-target-proxy"
  url_map = google_compute_url_map.url_map.id
  ssl_certificates = [
    google_compute_managed_ssl_certificate.lb_default.name
  ]
  depends_on = [
    google_compute_managed_ssl_certificate.lb_default
  ]
}

