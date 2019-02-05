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
  sensitive = true
}

resource "random_string" "rails_secret_dev" {
  length  = 128
  special = false
}
output "rails_secret_dev" {
  value = "${random_string.rails_secret_dev.result}"
  description = "Rails Dev secret string"
  sensitive = true
}

resource "random_string" "rails_secret_staging" {
  length  = 128
  special = false
}
output "rails_secret_staging" {
  value = "${random_string.rails_secret_staging.result}"
  description = "Rails staging secret string"
  sensitive = true
}

# dev SSO stuff
resource "random_string" "sso_cookie_secret_dev" {
  length  = 32
}
output "sso_cookie_secret_dev" {
  value = "${random_string.sso_cookie_secret_dev.result}"
  description = "SSO cookie secret string for dev"
  sensitive = true
}

resource "tls_private_key" "sso_dev" {
  algorithm   = "RSA"
  rsa_bits = 4096
}
output "sso_key_dev" {
  value = "${tls_private_key.sso_dev.private_key_pem}"
  description = "SSO JWT key for dev"
  sensitive = true
}
output "sso_pubkey_dev" {
  value = "${tls_private_key.sso_dev.public_key_pem}"
  description = "SSO JWT pubkey for dev"
}

# staging SSO stuff
resource "random_string" "sso_cookie_secret_staging" {
  length  = 32
}
output "sso_cookie_secret_staging" {
  value = "${random_string.sso_cookie_secret_staging.result}"
  description = "SSO cookie secret string for staging"
  sensitive = true
}

resource "tls_private_key" "sso_staging" {
  algorithm   = "RSA"
  rsa_bits = 4096
}
output "sso_key_staging" {
  value = "${tls_private_key.sso_staging.private_key_pem}"
  description = "SSO JWT key for staging"
  sensitive = true
}
output "sso_pubkey_staging" {
  value = "${tls_private_key.sso_staging.public_key_pem}"
  description = "SSO JWT pubkey for staging"
}

# production SSO stuff
resource "random_string" "sso_cookie_secret_production" {
  length  = 32
}
output "sso_cookie_secret_production" {
  value = "${random_string.sso_cookie_secret_production.result}"
  description = "SSO cookie secret string for production"
  sensitive = true
}

resource "tls_private_key" "sso_production" {
  algorithm   = "RSA"
  rsa_bits = 4096
}
output "sso_key_production" {
  value = "${tls_private_key.sso_production.private_key_pem}"
  description = "SSO JWT key for production"
  sensitive = true
}
output "sso_pubkey_production" {
  value = "${tls_private_key.sso_production.public_key_pem}"
  description = "SSO JWT pubkey for production"
}
