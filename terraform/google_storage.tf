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
    "serviceAccount:${var.project_id}@appspot.gserviceaccount.com",
  ]
}

output "logs_bucket" {
  value = "${google_storage_bucket.logs-bucket.url}"
  description = "Logs bucket for logs that are exported for ingestion by GSA IT Security"
}
