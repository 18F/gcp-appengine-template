variable "region" {
  type = "string"
  default = "us-east1"
}

variable "project_id" {
  type = "string"
}

resource "random_string" "rails_secret_production" {
  length  = 128
  special = false
}

output "rails_secret_production" {
  value = "${random_string.rails_secret_production.result}"
  description = "Rails secret string"
}

resource "random_string" "rails_secret_dev" {
  length  = 128
  special = false
}

output "rails_secret_dev" {
  value = "${random_string.rails_secret_dev.result}"
  description = "Rails Dev secret string"
}

resource "random_string" "rails_secret_staging" {
  length  = 128
  special = false
}

output "rails_secret_staging" {
  value = "${random_string.rails_secret_staging.result}"
  description = "Rails staging secret string"
}
