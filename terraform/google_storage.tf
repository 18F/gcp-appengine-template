# This is the user that is going to be used for syncing logs
resource "google_service_account" "logviewer" {
  account_id   = "logviewer"
  display_name = "Log viewer"
}
resource "google_service_account_key" "logviewerkey" {
  service_account_id = "${google_service_account.logviewer.name}"
}
output "logviewer_key" {
  value = "${base64decode(google_service_account_key.logviewerkey.private_key)}"
  description = "Private key for logviewer service account"
  sensitive = true
}


# log bucket
resource "google_storage_bucket" "logs-bucket" {
  name     = "logs-bucket-${var.project_id}"
  location = "${var.region}"
  storage_class = "REGIONAL"
  versioning = {
    enabled = true
  }
  lifecycle_rule = {
    action = {
      type = "Delete"
    }
    condition = {
      age = 60
    }
  }
}

resource "google_storage_bucket_iam_binding" "binding" {
  bucket = "${google_storage_bucket.logs-bucket.name}"
  role        = "roles/storage.objectViewer"

  members = [
    "serviceAccount:${google_service_account.logviewer.email}",
  ]
}

output "logs_bucket" {
  value = "${google_storage_bucket.logs-bucket.url}"
  description = "Logs bucket for logs that are exported for ingestion by GSA IT Security"
}
