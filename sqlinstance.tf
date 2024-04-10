resource "google_sql_database_instance" "example_instance" {
  name                = var.sql_instance_name
  region              = var.region
  database_version    = var.database_version
  encryption_key_name = google_kms_crypto_key.sql_crypto_key.id

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
  name       = var.database_user_name
  instance   = google_sql_database_instance.example_instance.name
  password   = random_password.webapp_db_password.result
  depends_on = [google_sql_database_instance.example_instance]

}
