resource "google_kms_key_ring" "dataprotectionprovider" {
  project  = "${var.project_id}"
  name     = "gcp_pilot_key_ring"
  location = "${var.region}"
}

resource "google_kms_crypto_key" "AntiforgeryToken" {
  name     = "Microsoft-AspNetCore-Antiforgery-AntiforgeryToken-v1"
  key_ring = "${google_kms_key_ring.gcp_pilot_key_ring.id}"
  rotation_period = "100000s"

  lifecycle {
    prevent_destroy = true
  }
}

