# Allow in access from other services in this project
resource "google_app_engine_firewall_rule" "flexible_backends" {
  project = "${var.project_id}"
  priority = 1100
  action = "ALLOW"
  source_range = "10.0.0.1"
}

# Deny access to everything else
resource "google_app_engine_firewall_rule" "defaultdeny" {
  project = "${var.project_id}"
  priority = 20000
  action = "DENY"
  source_range = "*"
}
