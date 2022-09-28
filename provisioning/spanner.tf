resource "google_spanner_instance" "scstore" {
  config       = "nam6"
  display_name = var.service_name
  num_nodes    = 1
}

resource "google_spanner_database" "scstore" {
  instance = google_spanner_instance.scstore.name
  name     = var.service_name  
  deletion_protection = false
  database_dialect = "POSTGRESQL"
}

/*
resource "google_spanner_database" "scstore" {
  instance = google_spanner_instance.scstore.name
  name     = var.service_name
  ddl = [
    "CREATE TABLE products (id bigint NOT NULL,	name character varying(20) NOT NULL, price bigint NOT NULL, image character varying(100) NOT NULL, PRIMARY KEY(id))",
    "CREATE TABLE users (id bigint NOT NULL, name character varying(20) NOT NULL, PRIMARY KEY(id))",
    "CREATE TABLE checkouts (id character varying(40) NOT NULL,	user_id bigint,	product_id bigint, product_quantity bigint,	created_at date,PRIMARY KEY(id))"
  ]
  
  deletion_protection = false
  database_dialect = "POSTGRESQL"
}
*/