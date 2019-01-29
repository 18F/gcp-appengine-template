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

resource "random_string" "sso_shared_secret" {
  length  = 32
}
output "sso_shared_secret" {
  value = "${random_string.sso_shared_secret.result}"
  description = "SSO secret string"
  sensitive = true
}

resource "random_string" "sso_cookie_secret" {
  length  = 32
}
output "sso_cookie_secret" {
  value = "${random_string.sso_cookie_secret.result}"
  description = "SSO cookie secret string"
  sensitive = true
}

resource "tls_private_key" "sso" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}
output "sso_key" {
  value = "${tls_private_key.sso.private_key_pem}"
  description = "SSO JWT key"
  sensitive = true
}
resource "tls_self_signed_cert" "sso" {
  key_algorithm   = "ECDSA"
  private_key_pem = "${tls_private_key.sso.private_key_pem}"

  subject {
    common_name  = "none"
    organization = "GSA"
  }

  validity_period_hours = 26280

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}
output "sso_cert" {
  value = "${tls_self_signed_cert.sso.cert_pem}"
  description = "SSO JWT cert"
}
