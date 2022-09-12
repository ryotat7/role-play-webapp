resource "google_compute_network" "default" {
  name                    = var.service_name
  auto_create_subnetworks = true
}

resource "google_compute_address" "default" {
  name         = "ipv4-address"
  region       = var.region
  address_type = "EXTERNAL"
}

# Private VPC Connection for Cloud SQL
resource "google_compute_global_address" "private_ip_address" {
  provider = google-beta

  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.default.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider = google-beta

  network                 = google_compute_network.default.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}