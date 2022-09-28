# cf. https://github.com/terraform-google-modules/terraform-google-lb-http/blob/0c2815a248a00dee3385a4813e9f895e426baac2/examples/multi-mig-http-lb/mig.tf

// HTTP LB for MIGs
locals {
  health_check = {
    check_interval_sec  = 90
    timeout_sec         = null
    healthy_threshold   = null
    unhealthy_threshold = 3
    request_path        = "/"
    port                = 80
    host                = null
    logging             = null
  }
}

module "gce-lb-http" {
  source = "GoogleCloudPlatform/lb-http/google"
  name    = var.service_name
  project = var.project_id
  target_tags = [
    google_compute_network.default.name,
    module.cloud-nat-mig.router_name
  ]
  firewall_networks = [google_compute_network.default.name]

  url_map           = google_compute_url_map.ml-bkd-ml-mig-lb.self_link
  create_url_map    = false

  backends = {
    default = {

      description                     = null
      protocol                        = "HTTP"
      port                            = 80
      port_name                       = "http"
      timeout_sec                     = 10
      connection_draining_timeout_sec = null
      enable_cdn                      = true
      security_policy                 = null
      session_affinity                = null
      affinity_cookie_ttl_sec         = null
      custom_request_headers          = null
      custom_response_headers         = null

      health_check = local.health_check

      log_config = {
        enable      = true
        sample_rate = 1.0
      }

      groups = [
        {
          group                        = module.mig.instance_group
          balancing_mode               = null
          capacity_scaler              = null
          description                  = null
          max_connections              = null
          max_connections_per_instance = null
          max_connections_per_endpoint = null
          max_rate                     = null
          max_rate_per_instance        = null
          max_rate_per_endpoint        = null
          max_utilization              = null
        },
        {
          group                        = module.mig2.instance_group
          balancing_mode               = null
          capacity_scaler              = null
          description                  = null
          max_connections              = null
          max_connections_per_instance = null
          max_connections_per_endpoint = null
          max_rate                     = null
          max_rate_per_instance        = null
          max_rate_per_endpoint        = null
          max_utilization              = null
        }
      ]

      iap_config = {
        enable               = false
        oauth2_client_id     = ""
        oauth2_client_secret = ""
      }
    }

    mig1 = {
      description                     = null
      protocol                        = "HTTP"
      port                            = 80
      port_name                       = "http"
      timeout_sec                     = 10
      connection_draining_timeout_sec = null
      enable_cdn                      = true
      security_policy                 = null
      session_affinity                = null
      affinity_cookie_ttl_sec         = null
      custom_request_headers          = null
      custom_response_headers         = null

      health_check = local.health_check
      log_config = {
        enable      = true
        sample_rate = 1.0
      }
      groups = [
        {
          group                        = module.mig.instance_group
          balancing_mode               = null
          capacity_scaler              = null
          description                  = null
          max_connections              = null
          max_connections_per_instance = null
          max_connections_per_endpoint = null
          max_rate                     = null
          max_rate_per_instance        = null
          max_rate_per_endpoint        = null
          max_utilization              = null
        },
      ]

      iap_config = {
        enable               = false
        oauth2_client_id     = ""
        oauth2_client_secret = ""
      }
    }
  }
}

# url-map for multi-region MIGs with multi-region Cloud SQL read replia
resource "google_compute_url_map" "ml-bkd-ml-mig-lb" {
  name            = "${var.service_name}-multi-backend"
  default_service = module.gce-lb-http.backend_services["default"].self_link

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = module.gce-lb-http.backend_services["default"].self_link

    path_rule {
      paths = [
        "/checkout",
        "/checkout/*"
      ]
      service = module.gce-lb-http.backend_services["mig1"].self_link
    }
  }
}

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

module "cloud-nat-mig" {
  source = "terraform-google-modules/cloud-nat/google"
  //version    = "~> 1.4.0"
  router     = google_compute_router.mig.name
  project_id = var.project_id
  region     = var.region
  name       = "${var.service_name}-cloud-nat-mig"
}


module "cloud-nat-mig2" {
  source = "terraform-google-modules/cloud-nat/google"
  //version    = "~> 1.4.0"
  router     = google_compute_router.mig2.name
  project_id = var.project_id
  region     = var.region2
  name       = "${var.service_name}-cloud-nat-mig2"
}

# MIGs
module "mig_template" {
  source = "terraform-google-modules/vm/google//modules/instance_template"
  network = google_compute_network.default.self_link
  service_account = {
    email  = ""
    scopes = ["cloud-platform"]
  }
  name_prefix          = var.service_name
  machine_type         = var.gce_machine_type
  startup_script       = file("${path.module}/startup.sh")
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

module "mig_read_replica_template" {
  source = "terraform-google-modules/vm/google//modules/instance_template"
  network = google_compute_network.default.self_link
  service_account = {
    email  = ""
    scopes = ["cloud-platform"]
  }
  name_prefix          = var.service_name
  machine_type         = var.gce_machine_type
  startup_script       = file("${path.module}/startup.sh")
  source_image_family  = "debian-10"
  source_image_project = "debian-cloud"
  tags = [
    google_compute_network.default.name,
    module.cloud-nat-mig.router_name
  ]
  metadata = {
    enable-oslogin = "TRUE"
    db_hostname    = google_sql_database_instance.scstore_read_replica2.private_ip_address
    db_port        = 5432
    db_username    = var.service_name
    db_name        = var.service_name
    db_password    = var.service_name
  }
}

module "mig" {
  source = "terraform-google-modules/vm/google//modules/mig"
  instance_template = module.mig_template.self_link
  region            = var.region
  hostname          = var.service_name
  target_size       = 8
  named_ports = [{
    name = "http",
    port = 80
  }]
  network = google_compute_network.default.self_link
}

module "mig2" {
  source = "terraform-google-modules/vm/google//modules/mig"
  instance_template = module.mig_read_replica_template.self_link
  region            = var.region2
  hostname          = var.service_name
  target_size       = 2
  named_ports = [{
    name = "http",
    port = 80
  }]
  network = google_compute_network.default.self_link
}
