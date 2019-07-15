// Production Postgres Database
resource "google_sql_database_instance" "postgres" {
  name = "postgres"
  database_version = "POSTGRES_9_6"
  region = "${var.region}"

  settings {
    tier = "db-f1-micro"
    availability_type = "REGIONAL"
    backup_configuration {
      enabled = true
      start_time = "05:00"
    }
  }
}

resource "random_string" "postgres_password" {
  length  = 24
  special = false
}

resource "google_sql_user" "postgres" {
  name     = "postgres"
  password = "${random_string.postgres_password.result}"
  instance = "${google_sql_database_instance.postgres.name}"
  depends_on = ["google_sql_database_instance.postgres"]
}
