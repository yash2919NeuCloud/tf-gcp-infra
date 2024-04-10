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
  location = var.region
  encryption {
    default_kms_key_name = google_kms_crypto_key.storage_crypto_key.id

  }
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
