resource "google_app_engine_firewall_rule" "allow_apps1" {
  project = "${var.project_id}"
  priority = 1000
  action = "ALLOW"
  source_range = "0.1.0.40/32"
}

resource "google_app_engine_firewall_rule" "allow_apps2" {
  project = "${var.project_id}"
  priority = 1100
  action = "ALLOW"
  source_range = "10.0.0.1/32"
}

resource "google_app_engine_firewall_rule" "disallow_outbound" {
  project = "${var.project_id}"
  priority = 2147483646
  action = "DENY"
  source_range = "10.0.0.1"
}
