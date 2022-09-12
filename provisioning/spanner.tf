resource "google_spanner_instance" "scstore" {
  config       = "nam6"
  display_name = var.service_name
  num_nodes    = 1
}


resource "google_spanner_database" "scstore" {
  instance = google_spanner_instance.scstore.name
  name     = var.service_name
  // version_retention_period = "3d"
  ddl = [
    "CREATE TABLE products (id INT64 NOT NULL, name STRING(20) NOT NULL, price INT64 NOT NULL, image STRING(100) NOT NULL,) PRIMARY KEY(id)",
    "CREATE TABLE users (id INT64 NOT NULL,	name STRING(20) NOT NULL,) PRIMARY KEY(id)",
    "CREATE TABLE checkouts (id STRING(40) NOT NULL, user_id INT64,	product_id INT64, product_quantity INT64, created_at DATE,) PRIMARY KEY(id)"
  ]
  deletion_protection = false
  database_dialect = POSTGRESQL
}
