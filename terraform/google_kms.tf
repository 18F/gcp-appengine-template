resource "google_kms_key_ring" "dataprotectionprovider" {
  project  = "${var.project_id}"
  name     = "dataprotectionprovider"
  location = "${var.region}"
}

resource "google_kms_crypto_key" "AntiforgeryToken" {
  name     = "Microsoft-AspNetCore-Antiforgery-AntiforgeryToken-v1"
  key_ring = "${google_kms_key_ring.dataprotectionprovider.id}"
  rotation_period = "100000s"

  lifecycle {
    prevent_destroy = true
  }
}

