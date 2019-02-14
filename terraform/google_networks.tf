resource "google_compute_network" "dev_backend" {
  name = "dev_backend"
}

resource "google_compute_network" "staging_backend" {
  name = "staging_backend"
}

resource "google_compute_network" "production_backend" {
  name = "production_backend"
}

resource "google_compute_firewall" "dev" {
  name    = "dev"
  network = "${google_compute_network.dev_backend.name}"

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
  network = "${google_compute_network.staging_backend.name}"

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
  network = "${google_compute_network.production_backend.name}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["80-2000"]
  }

  source_tags = ["ssoproxy_production"]
}
