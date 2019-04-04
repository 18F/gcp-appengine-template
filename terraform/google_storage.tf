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


# dev log bucket
resource "google_storage_bucket" "logs-bucket-dev" {
  name     = "logs-bucket-dev-${var.project_id}"
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

resource "google_storage_bucket_acl" "logs-bucket-acl-dev" {
  bucket = "${google_storage_bucket.logs-bucket-dev.name}"

  role_entity = [
    "READER:${google_service_account.logviewer.email}",
  ]
}

output "logs_bucket_dev" {
  value = "${google_storage_bucket.logs-bucket-dev.url}"
  description = "Logs bucket for dev logs that are exported for ingestion by GSA IT Security"
}


# staging log bucket
resource "google_storage_bucket" "logs-bucket-staging" {
  name     = "logs-bucket-staging-${var.project_id}"
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

resource "google_storage_bucket_acl" "logs-bucket-acl-staging" {
  bucket = "${google_storage_bucket.logs-bucket-staging.name}"

  role_entity = [
    "READER:${google_service_account.logviewer.email}",
  ]
}

output "logs_bucket_staging" {
  value = "${google_storage_bucket.logs-bucket-staging.url}"
  description = "Logs bucket for staging logs that are exported for ingestion by GSA IT Security"
}


# prod log bucket
resource "google_storage_bucket" "logs-bucket-prod" {
  name     = "logs-bucket-prod-${var.project_id}"
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

resource "google_storage_bucket_acl" "logs-bucket-acl-prod" {
  bucket = "${google_storage_bucket.logs-bucket-prod.name}"

  role_entity = [
    "READER:${google_service_account.logviewer.email}",
  ]
}

output "logs_bucket_master" {
  value = "${google_storage_bucket.logs-bucket-prod.url}"
  description = "Logs bucket for production logs that are exported for ingestion by GSA IT Security"
}
