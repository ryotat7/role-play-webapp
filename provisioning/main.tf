terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      //version = "~> 4.17.0"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
}

provider "google-beta" {
  project     = var.project_id
  region      = var.region
}