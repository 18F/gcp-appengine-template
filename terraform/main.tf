
module "production" {
  source = "./gcp-environment"
}

module "staging" {
  source = "./gcp-environment"
  project_id = "${var.staging_project_id}"
  providers = {
    google = "google.staging"
  }
}

module "dev" {
  source = "./gcp-environment"
  project_id = "${var.dev_project_id}"
  providers = {
    google = "google.dev"
  }
}
