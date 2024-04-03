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



resource "google_service_account" "service_account" {
  account_id   = "service-account-1"
  display_name = "Service Account"
}


# resource "google_compute_instance" "instance-1" {
#   machine_type = var.machine_type
#   name         = var.instance_name
#   tags         = var.tags
#   zone         = var.zone
#   metadata_startup_script = templatefile("./startup.tpl", {
#     db_host     = google_sql_database_instance.example_instance.first_ip_address,
#     db_password = random_password.webapp_db_password.result,
#     db_database = google_sql_database.webapp_db.name,
#     db_user     = google_sql_user.webapp_db_user.name
#   })

#   service_account {
#     email  = google_service_account.service_account.email
#     scopes = ["cloud-platform"]
#   }

#   depends_on = [
#     google_sql_database_instance.example_instance
#   ]

#   boot_disk {
#     device_name = "Vm1"

#     initialize_params {
#       image = var.boot_disk_image
#       size  = var.boot_disk_size
#       type  = var.boot_disk_type
#     }
#   }

#   network_interface {
#     subnetwork = google_compute_subnetwork.webapp_subnet.id
#     access_config {
#       network_tier = "PREMIUM"
#     }

#   }
# }
# Regional Compute Instance Template
resource "google_compute_region_instance_template" "template" {
  name         = "instance-1"
  machine_type = "e2-medium"

  disk {
    source_image = var.boot_disk_image
    auto_delete  = true
    boot         = true
    # type         = "pd-standard"
    disk_size_gb = var.boot_disk_size
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
  tags = ["allow-health-check", "http-server", "https-server", "lb-health-check", ]
}

# Compute Health Check
resource "google_compute_health_check" "health_check" {
  name               = "web-health-check"
  check_interval_sec = 30
  timeout_sec        = 10
  http_health_check {
    port         = 3000
    request_path = "/healthz"
  }

}


resource "google_compute_region_autoscaler" "autoscaler" {
  name   = "web-autoscaler"
  target = google_compute_region_instance_group_manager.manager.id
  autoscaling_policy {
    min_replicas    = 1
    max_replicas    = 3
    cooldown_period = 80
    cpu_utilization {
      target = 0.05
    }
  }
}


resource "google_compute_region_instance_group_manager" "manager" {
  name               = "web-instance-group-manager"
  base_instance_name = "web-instance"
  target_size        = 2


  version {
    instance_template = google_compute_region_instance_template.template.id
    name              = "primary"
  }
  named_port {
    name = "http"
    port = 3000
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.health_check.id
    initial_delay_sec = 250
  }
}

resource "google_compute_firewall" "allow_lb" {
  name      = "allow-lb"
  network   = google_compute_network.my_vpc.id
  direction = "INGRESS"
  priority  = 1000

  allow {
    protocol = "tcp"
    ports    = ["80", "443", "3000"]
  }

  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
}

resource "google_compute_global_address" "default" {
  name         = "address-name"
  address_type = "EXTERNAL"

}

resource "google_compute_global_forwarding_rule" "forwarding_rule" {
  name                  = "web-forwarding-rule"
  target                = google_compute_target_http_proxy.proxy.self_link
  port_range            = "3000-3000"
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
  timeout_sec   = 30
  health_checks = [google_compute_health_check.health_check.id]
  backend {
    group           = google_compute_region_instance_group_manager.manager.instance_group
    capacity_scaler = 1.0
    balancing_mode  = "UTILIZATION"

  }
}

resource "google_compute_target_http_proxy" "proxy" {
  name    = "web-target-proxy"
  url_map = google_compute_url_map.url_map.id
}



# resource "google_compute_instance" "instance-1" {
#   machine_type = var.machine_type
#   name         = var.instance_name
#   tags         = var.tags
#   zone         = var.zone
#   metadata_startup_script = templatefile("./startup.tpl", {
#     db_host     = google_sql_database_instance.example_instance.first_ip_address,
#     db_password = random_password.webapp_db_password.result,
#     db_database = google_sql_database.webapp_db.name,
#     db_user     = google_sql_user.webapp_db_user.name
#   })

#   service_account {
#     email  = google_service_account.service_account.email
#     scopes = ["cloud-platform"]
#   }

#   depends_on = [
#     google_sql_database_instance.example_instance
#   ]

#   boot_disk {
#     device_name = "Vm1"

#     initialize_params {
#       image = var.boot_disk_image
#       size  = var.boot_disk_size
#       type  = var.boot_disk_type
#     }
#   }

#   network_interface {
#     subnetwork = google_compute_subnetwork.webapp_subnet.id
#     access_config {
#       network_tier = "PREMIUM"
#     }

#   }
# }

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
  special = false
}
resource "google_sql_user" "webapp_db_user" {
  name     = var.database_user_name
  instance = google_sql_database_instance.example_instance.name
  password = random_password.webapp_db_password.result

}

resource "google_pubsub_topic" "verify_email" {
  name = var.google_pubsub_topic_name
}

resource "google_pubsub_subscription" "verify_email_subscription" {
  name                       = "verify_email_subscription"
  topic                      = google_pubsub_topic.verify_email.name
  ack_deadline_seconds       = var.ack_deadline_seconds
  message_retention_duration = var.message_retention_duration
  expiration_policy {
    ttl = var.message_retention_duration
  }
}

resource "google_storage_bucket" "yash_cl_bucket291_b" {
  name     = var.google_storage_bucket_name
  location = var.location
}

resource "google_storage_bucket_object" "ziparchive" {
  name   = "cloud_func.zip"
  bucket = google_storage_bucket.yash_cl_bucket291_b.name
  source = var.src
}

resource "google_vpc_access_connector" "vpcconnector" {
  name          = "vpcconnector"
  region        = var.region
  network       = google_compute_network.my_vpc.id
  machine_type  = var.machine_type_vpc_connector
  ip_cidr_range = var.ip_cidr_range
  min_instances = var.min_instances
  max_instances = var.max_instances


}
resource "google_pubsub_subscription_iam_binding" "subscription_binding" {
  project      = var.project_id
  subscription = google_pubsub_subscription.verify_email_subscription.name
  role         = "roles/pubsub.subscriber"
  members = [
    "serviceAccount:${google_service_account.service_account.email}"
  ]
}


resource "google_cloudfunctions2_function" "cloud_function" {
  name     = "cloud-function"
  location = var.region
  build_config {
    entry_point = var.entry_point
    runtime     = var.runtime
    source {
      storage_source {
        bucket = google_storage_bucket.yash_cl_bucket291_b.name
        object = google_storage_bucket_object.ziparchive.name
      }
    }
  }
  service_config {
    max_instance_count            = var.max_instance_count
    timeout_seconds               = var.timeout_seconds
    available_memory              = var.available_memory
    vpc_connector                 = google_vpc_access_connector.vpcconnector.name
    vpc_connector_egress_settings = var.vpc_connector_egress_settings
    environment_variables = {

      DB_USER     = "${var.database_name}"
      DB_DATABASE = "${var.database_user_name}"
      DB_HOST     = "${google_sql_database_instance.example_instance.first_ip_address}"
      DB_PASSWORD = "${random_password.webapp_db_password.result}"
      key         = "${var.key}"

    }

  }
  event_trigger {
    trigger_region = var.region
    event_type     = var.event_type
    pubsub_topic   = google_pubsub_topic.verify_email.id
    retry_policy   = var.retry_policy
  }

  # depends_on = [google]


}



