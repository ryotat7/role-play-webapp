resource "google_project_service" "artifact_registry_api" {
  service            = "artifactregistry.googleapis.com"
  provider           = google-beta
  disable_on_destroy = false
}

resource "google_artifact_registry_repository" "scstore" {
  location      = "us"
  repository_id = var.service_name
  description   = "docker repository for ${var.service_name}"
  format        = "DOCKER"
}