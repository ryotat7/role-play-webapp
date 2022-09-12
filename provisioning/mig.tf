# https://github.com/terraform-google-modules/terraform-google-lb-http/blob/0c2815a248a00dee3385a4813e9f895e426baac2/examples/multi-mig-http-lb/mig.tf

# Cloud Routers and NATs
# Router and Cloud NAT are required for installing packages from repos (apache, php etc)
resource "google_compute_router" "mig" {
  name    = var.service_name
  network = google_compute_network.default.self_link
  region  = var.region
}

resource "google_compute_router" "mig2" {
  name    = var.service_name
  network = google_compute_network.default.self_link
  region  = var.region2
}

resource "google_compute_router" "mig3" {
  name    = var.service_name
  network = google_compute_network.default.self_link
  region  = var.region3
}

module "cloud-nat-mig" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "~> 1.4.0"
  router     = google_compute_router.mig.name
  project_id = var.project_id
  region     = var.region
  name       = "${var.service_name}-cloud-nat-mig"
}

module "cloud-nat-mig2" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "~> 1.4.0"
  router     = google_compute_router.mig2.name
  project_id = var.project_id
  region     = var.region2
  name       = "${var.service_name}-cloud-nat-mig2"
}

module "cloud-nat-mig3" {
  source     = "terraform-google-modules/cloud-nat/google"
  version    = "~> 1.4.0"
  router     = google_compute_router.mig3.name
  project_id = var.project_id
  region     = var.region3
  name       = "${var.service_name}-cloud-nat-mig3"
}


# MIGs
module "mig_template" {
  source     = "terraform-google-modules/vm/google//modules/instance_template"
  version    = "6.2.0"
  network    = google_compute_network.default.self_link
  service_account = {
    email  = ""
    scopes = ["cloud-platform"]
  }
  name_prefix          = var.service_name
  //startup_script       = data.template_file.group-startup-script.rendered
  startup_script       = file("${path.module}/startup.sh")
  //source_image         = var.gce_image_name
  source_image_family  = "debian-10"
  source_image_project = "debian-cloud"
  tags = [
    google_compute_network.default.name,
    module.cloud-nat-mig.router_name
  ]
  metadata = {
    enable-oslogin = "TRUE"
    db_hostname    = google_sql_database_instance.scstore.private_ip_address
    db_port        = 5432
    db_username    = var.service_name
    db_name        = var.service_name
    db_password    = var.service_name
  }

}

module "mig" {
  source            = "terraform-google-modules/vm/google//modules/mig"
  version           = "6.2.0"
  instance_template = module.mig_template.self_link
  region            = var.region
  hostname          = var.service_name
  target_size       = 4
  named_ports = [{
    name = "http",
    port = 80
  }]
  network    = google_compute_network.default.self_link
}

module "mig2" {
  source            = "terraform-google-modules/vm/google//modules/mig"
  version           = "6.2.0"
  instance_template = module.mig_template.self_link
  region            = var.region2
  hostname          = var.service_name
  target_size       = 1
  named_ports = [{
    name = "http",
    port = 80
  }]
  network    = google_compute_network.default.self_link
}

module "mig3" {
  source            = "terraform-google-modules/vm/google//modules/mig"
  version           = "6.2.0"
  instance_template = module.mig_template.self_link
  region            = var.region3
  hostname          = var.service_name
  target_size       = 1
  named_ports = [{
    name = "http",
    port = 80
  }]
  network    = google_compute_network.default.self_link
}