// Production Postgres Database
resource "google_sql_database_instance" "production" {
  name = "production"
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

resource "random_string" "postgres_password_production" {
  length  = 24
  special = false
}

resource "google_sql_user" "postgres-production" {
  name     = "postgres"
  password = "${random_string.postgres_password_production.result}"
  instance = "${google_sql_database_instance.production.name}"
}

output "postgres_password_production" {
  value = "${random_string.postgres_password_production.result}"
  description = "Postgres production password"
  sensitive = true
}

output "postgres_username_production" {
  value = "${google_sql_user.postgres-production.name}"
  description = "Postgres production username"
}

output "postgres_instance_production" {
  value = "${google_sql_database_instance.production.connection_name}"
  description = "Postgres production instance ID"
}


// Dev Postgres Database
resource "google_sql_database_instance" "dev" {
  name = "dev"
  database_version = "POSTGRES_9_6"
  region = "${var.region}"

  settings {
    tier = "db-f1-micro"
  }
}

resource "random_string" "postgres_password_dev" {
  length  = 24
  special = false
}

resource "google_sql_user" "postgres-dev" {
  name     = "postgres"
  password = "${random_string.postgres_password_dev.result}"
  instance = "${google_sql_database_instance.dev.name}"
}

output "postgres_password_dev" {
  value = "${random_string.postgres_password_dev.result}"
  description = "Postgres dev password"
  sensitive = true
}

output "postgres_username_dev" {
  value = "${google_sql_user.postgres-dev.name}"
  description = "Postgres dev username"
}

output "postgres_instance_dev" {
  value = "${google_sql_database_instance.dev.connection_name}"
  description = "Postgres dev instance ID"
}

// Staging Postgres Database
resource "google_sql_database_instance" "staging" {
  name = "staging"
  database_version = "POSTGRES_9_6"
  region = "${var.region}"

  settings {
    tier = "db-f1-micro"
  }
}

resource "random_string" "postgres_password_staging" {
  length  = 24
  special = false
}

resource "google_sql_user" "postgres-staging" {
  name     = "postgres"
  password = "${random_string.postgres_password_staging.result}"
  instance = "${google_sql_database_instance.staging.name}"
}

output "postgres_password_staging" {
  value = "${random_string.postgres_password_staging.result}"
  description = "Postgres staging password"
  sensitive = true
}

output "postgres_username_staging" {
  value = "${google_sql_user.postgres-staging.name}"
  description = "Postgres staging username"
}

output "postgres_instance_staging" {
  value = "${google_sql_database_instance.staging.connection_name}"
  description = "Postgres staging instance ID"
}
