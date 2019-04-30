resource "random_string" "rails_secret" {
  length  = 128
  special = false
}

resource "random_string" "signature_key" {
  length  = 128
  special = false
}

# SSO stuff
resource "random_string" "sso_cookie_secret" {
  length  = 32
}
resource "tls_private_key" "sso" {
  algorithm   = "RSA"
  rsa_bits = 2048
}
resource "tls_self_signed_cert" "sso" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.sso.private_key_pem}"

  subject {
    common_name  = "${var.environment}"
    organization = "GSA"
  }

  validity_period_hours = 26280

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}
