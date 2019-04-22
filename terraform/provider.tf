provider "google" {
  credentials = "${file("~/gcloud-service-key.json")}"
  project     = "${var.project_id}"
  region      = "${var.region}"
}

terraform {
  backend "gcs" {
    credentials = "~/gcloud-service-key.json"
    # Cannot interpolate, so we will feed this in on the commandline
    #bucket      = "gcp-terraform-state-${var.project_id}"
  }
}
