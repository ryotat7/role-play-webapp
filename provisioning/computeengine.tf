/*
resource "google_compute_instance" "scstore" {
  name         = var.service_name
  machine_type = var.gce_machine_type
  zone         = var.zone
  tags         = ["http-server"]
  deletion_protection = false
  boot_disk {
    initialize_params {
      image = var.gce_image_name
    }
  }
  network_interface {
    network = google_compute_network.default.self_link
    access_config {
      nat_ip = google_compute_address.default.address
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
    db_hostname    = google_sql_database_instance.scstore.private_ip_address
    db_port        = 5432
    db_username    = var.service_name
    db_name        = var.service_name
    db_password    = var.service_name
  }

  metadata_startup_script = file("${path.module}/startup.sh")

  service_account {
    email = ""
    scopes = ["cloud-platform"]
  }
}
*/