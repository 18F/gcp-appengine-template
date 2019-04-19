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

# allow the unique service account to write to the logs bucket
resource "google_project_iam_binding" "binding" {
  role        = "roles/storage.objectCreator"
  members = [
    "${google_logging_project_sink.securitystuff.writer_identity}",
  ]
}

# send logs to the log bucket
resource "google_logging_project_sink" "securitystuff" {
    name = "securitystuff-sink"
    destination = "storage.googleapis.com/${google_storage_bucket.logs-bucket.name}"

    filter = "resource.type=service_account OR resource.type=audited_resource OR protoPayload.@type=type.googleapis.com/google.cloud.audit.AuditLog OR resource.type=security_scanner_scan_config OR logName=projects/${var.project_id}/logs/appengine.googleapis.com%2Fvm.syslog"

    # Use a unique writer (creates a unique service account used for writing)
    unique_writer_identity = true
}
