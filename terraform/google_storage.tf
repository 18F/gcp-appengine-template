resource "google_storage_bucket" "log-bucket" {
  name     = "log-bucket-${var.project_id}"
  location = "${var.region}"
  storage_class = "REGIONAL"
}

resource "google_storage_bucket" "storage-bucket" {
  name     = "storage-bucket-${var.project_id}"
  location = "${var.region}"
  storage_class = "REGIONAL"
  versioning = {
    enabled = true
  }
  logging =  {
    log_bucket = "${google_storage_bucket.log-bucket.name}"
  }
}

output "logs_bucket" {
  value = "${google_storage_bucket.log-bucket.url}"
  description = "Stores logs from ${google_storage_bucket.storage-bucket.name}"
}

output "pilot_bucket" {
  value = "${google_storage_bucket.storage-bucket.url}"
  description = "Example Google Storage bucket"
}
