resource "random_string" "rdm_sting" {
  length  = 5
  special = false
}

resource "google_kms_key_ring" "key_ring" {
  name     = "key-ring${random_string.rdm_sting.result}"
  project  = var.project_id
  location = var.region
}

resource "google_kms_crypto_key" "storage_crypto_key" {
  name            = "storage-crypddto-key-1"
  key_ring        = google_kms_key_ring.key_ring.id
  rotation_period = "2592000s" # 30 days in seconds (30 * 24 * 60 * 60)
  purpose         = "ENCRYPT_DECRYPT"
  lifecycle {
    prevent_destroy = false
  }

}

resource "google_kms_crypto_key_iam_binding" "crypto_key_storage_binding" {
  # provider      = google-beta
  crypto_key_id = google_kms_crypto_key.storage_crypto_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members = [
    # "serviceAccount:${google_service_account.service_account.email}",
    "serviceAccount:service-823125647969@gs-project-accounts.iam.gserviceaccount.com",
  ]
}

resource "google_kms_crypto_key" "vm_key" {
  name            = "vm-crypto-kecy-1"
  key_ring        = google_kms_key_ring.key_ring.id
  rotation_period = "2592000s" # 30 days in seconds (30 * 24 * 60 * 60)
  purpose         = "ENCRYPT_DECRYPT"
  lifecycle {
    prevent_destroy = false
  }
}
resource "google_kms_crypto_key_iam_binding" "crypto_vm_key_binding" {
  # provider      = google-beta
  crypto_key_id = google_kms_crypto_key.vm_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  # members = [
  #   "serviceAccount:${google_service_account.service_account.email}",
  # ]
  members = [
    "serviceAccount:service-823125647969@compute-system.iam.gserviceaccount.com",
  ]

}
resource "google_kms_crypto_key" "sql_crypto_key" {
  name            = "sql-crypto-dkey-1"
  key_ring        = google_kms_key_ring.key_ring.id
  rotation_period = "2592000s" # 30 days in seconds (30 * 24 * 60 * 60)
  purpose         = "ENCRYPT_DECRYPT"
  lifecycle {
    prevent_destroy = false
  }
}

resource "google_project_service_identity" "service_cloud_sql" {
  project  = var.project_id
  provider = google-beta
  service  = "sqladmin.googleapis.com"
}
resource "google_kms_crypto_key_iam_binding" "crypto_key_sql_binding" {
  # provider      = google-beta
  crypto_key_id = google_kms_crypto_key.sql_crypto_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members = [
    "serviceAccount:${google_project_service_identity.service_cloud_sql.email}"
  ]
}



