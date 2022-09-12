variable "project_id" {}

variable "region" {
    description = "Region"
    type        = string
    default     = "us-central1"
}

variable "region2" {
    description = "Region"
    type        = string
    default     = "us-west1"
}

variable "region3" {
    description = "Region"
    type        = string
    default     = "us-east1"
}

variable "zone" {
    description = "Zone"
    type        = string
    default     = "us-central1-c"
}

variable "service_name" {
    description = "Service name"
    type        = string
}

variable "benchmark_service_account_name" {
    description = "Service Account name for Benchmark"
    type        = string
}

variable "gce_machine_type" {
    description = "GCE Machine Type"
    type        = string
    default     = "e2-standard-2"
}

variable "gce_image_name" {
    description = "GCE Image Name"
    type        = string
    default     = "debian-cloud/debian-10"
}

variable "cloudsql_machine_type" {
    description = "Cloud SQL Machine Type"
    type        = string
    default     = "db-custom-1-3840"
}

variable "database_scstore_password" {
    description = "Password of database user: scstore"
    type = string
}