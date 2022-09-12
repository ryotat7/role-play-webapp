resource "random_id" "db_instance_name_suffix" {
  byte_length = 4
}

resource "google_sql_database_instance" "scstore" {
  name             = "${var.service_name}-${random_id.db_instance_name_suffix.hex}"
  database_version = "POSTGRES_14"
  region           = var.region
  deletion_protection = false

  depends_on = [google_service_networking_connection.private_vpc_connection]

  settings {
    tier              = var.cloudsql_machine_type
    availability_type = "REGIONAL"
    // availability_type = "ZONAL"

    ip_configuration {
      ipv4_enabled        = false
      private_network     = google_compute_network.default.id
      require_ssl         = false
      //allocated_ip_range  = null
    }

    location_preference {
      zone             = var.zone
    }
    /*
    database_flags {
        name  = "cloudsql.iam_authentication"
        value = "on"
    }*/
  }
}

resource "google_sql_database" "scstore" {
  name     = var.service_name
  instance = google_sql_database_instance.scstore.name
}

resource "google_sql_user" "scstore" {
  name     = var.service_name
  password = var.database_scstore_password
  instance = google_sql_database_instance.scstore.name
}

// read replicas
resource "google_sql_database_instance" "scstore_read_replica" {
  name                 = "${var.service_name}-${random_id.db_instance_name_suffix.hex}-read-replica"
  master_instance_name = google_sql_database_instance.scstore.name
  region               = var.region
  database_version     = "POSTGRES_14"

  replica_configuration {
    failover_target = false
  }

  settings {
    tier              = var.cloudsql_machine_type
    availability_type = "REGIONAL"

    ip_configuration {
      ipv4_enabled        = false
      private_network     = google_compute_network.default.id
      require_ssl         = false
    }
  }
  deletion_protection = false # set to true to prevent destruction of the resource
}

resource "google_sql_database_instance" "scstore_read_replica2" {
  name                 = "${var.service_name}-${random_id.db_instance_name_suffix.hex}-read-replica-2"
  master_instance_name = google_sql_database_instance.scstore.name
  region               = var.region2
  database_version     = "POSTGRES_14"

  replica_configuration {
    failover_target = false
  }

  settings {
    tier              = var.cloudsql_machine_type
    availability_type = "REGIONAL"

    ip_configuration {
      ipv4_enabled        = false
      private_network     = google_compute_network.default.id
      require_ssl         = false
    }
  }
  deletion_protection = false # set to true to prevent destruction of the resource
}

resource "google_sql_database_instance" "scstore_read_replica3" {
  name                 = "${var.service_name}-${random_id.db_instance_name_suffix.hex}-read-replica-3"
  master_instance_name = google_sql_database_instance.scstore.name
  region               = var.region3
  database_version     = "POSTGRES_14"

  replica_configuration {
    failover_target = false
  }

  settings {
    tier              = var.cloudsql_machine_type
    availability_type = "REGIONAL"

    ip_configuration {
      ipv4_enabled        = false
      private_network     = google_compute_network.default.id
      require_ssl         = false
    }
  }
  deletion_protection = false # set to true to prevent destruction of the resource
}