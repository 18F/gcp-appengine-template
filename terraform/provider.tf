provider "google" {
  credentials = "${file("~/gcloud-service-key.json")}"
  project     = "${var.project_id}"
  region      = "${var.region}"
}

provider "google" {
  alias = "google-prod"
  credentials = "${file("~/gcloud-service-key.json")}"
  project     = "${var.project_id}"
  region      = "${var.region}"
}

provider "google" {
  alias = "google-staging"
  credentials = "${file("~/staging-gcloud-service-key.json")}"
  project     = "${var.staging_project_id}"
  region      = "${var.region}"
}

provider "google" {
  alias = "google-dev"
  credentials = "${file("~/dev-gcloud-service-key.json")}"
  project     = "${var.dev_project_id}"
  region      = "${var.region}"
}

terraform {
  backend "gcs" {
    credentials = "~/gcloud-service-key.json"
    # Cannot interpolate, so we will feed this in on the commandline
    #bucket      = "gcp-terraform-state-${var.project_id}"
  }
}
