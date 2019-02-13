# Allow in access from other services in this project
resource "google_app_engine_firewall_rule" "rule" {
  project = "${var.project_id}"
  priority = 1000
  action = "ALLOW"
  source_range = "0.1.0.40"
}
resource "google_app_engine_firewall_rule" "rule" {
  project = "${var.project_id}"
  priority = 1100
  action = "ALLOW"
  source_range = "10.0.0.1"
}

# Deny access to everything else
resource "google_app_engine_firewall_rule" "rule" {
  project = "${var.project_id}"
  priority = default
  action = "DENY"
  source_range = "*"
}
