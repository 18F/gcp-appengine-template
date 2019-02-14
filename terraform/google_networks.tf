resource "google_compute_network" "dev-backend" {
  name = "dev-backend"
}

resource "google_compute_network" "staging-backend" {
  name = "staging-backend"
}

resource "google_compute_network" "production-backend" {
  name = "production-backend"
}

resource "google_compute_firewall" "dev" {
  name    = "dev"
  network = "${google_compute_network.dev-backend.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80-2000"]
  }

  source_tags = ["ssoproxy_dev"]
}

resource "google_compute_firewall" "staging" {
  name    = "staging"
  network = "${google_compute_network.staging-backend.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80-2000"]
  }

  source_tags = ["ssoproxy_staging"]
}

resource "google_compute_firewall" "production" {
  name    = "production"
  network = "${google_compute_network.production-backend.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80-2000"]
  }

  source_tags = ["ssoproxy_production"]
}
