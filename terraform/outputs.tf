output "postgres_password" {
  value = "${random_string.postgres_password.result}"
  description = "Postgres password"
  sensitive = true
}

output "postgres_username" {
  value = "${google_sql_user.postgres.name}"
  description = "Postgres username"
}

output "postgres_instance" {
  value = "${google_sql_database_instance.postgres.connection_name}"
  description = "Postgres instance ID"
}

output "rails_secret" {
  value = "${random_string.rails_secret.result}"
  description = "Rails secret string"
  sensitive = true
}

output "signature_key" {
  value = "${random_string.signature_key.result}"
  description = "signature_key"
  sensitive = true
}

output "sso_cookie_secret" {
  value = "${random_string.sso_cookie_secret.result}"
  description = "SSO cookie secret string"
  sensitive = true
}

output "sso_key" {
  value = "${tls_private_key.sso.private_key_pem}"
  description = "SSO JWT key"
  sensitive = true
}

output "sso_cert" {
  value = "${tls_self_signed_cert.sso.cert_pem}"
  description = "SSO JWT cert"
}

output "logs_bucket" {
  value = "${google_storage_bucket.logs-bucket.url}"
  description = "Logs bucket for logs that are exported for ingestion by GSA IT Security"
}
