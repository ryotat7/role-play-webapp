resource "google_project_service" "cloud_run_api" {
  service            = "run.googleapis.com"
  provider           = google-beta
  disable_on_destroy = false
}

resource "google_cloud_run_service" "scstore" {
  provider = google-beta
  name     = "${var.service_name}--${var.region}"
  location = var.region
  project  = var.project_id

  template {
    spec {
      containers {
        image = "us-docker.pkg.dev/qwiklabs-gcp-01-f371c68da851/scstore/scstore-original:1.0.0"

        env {
          name  = "DB_HOSTNAME"
          value = "10.12.2.2"
          #value = google_sql_database_instance.scstore.private_ip_address
        }
        env {
          name  = "DB_PORT"
          value = "5432"
        }
        env {
          name  = "DB_USERNAME"
          value = var.service_name
        }
        env {
          name  = "DB_PASSWORD"
          value = var.service_name
        }
        env {
          name  = "DB_NAME"
          value = var.service_name
        }
        env {
          name  = "GIN_MODE"
          value = "release"
        }
        env {
          name  = "GOOGLE_CLOUD_PROJECT"
          value = var.project_id
        }
      }
    }
    metadata {
      annotations = {
        # Limit scale up to prevent any cost blow outs!
        "autoscaling.knative.dev/minScale" = "1"
        "autoscaling.knative.dev/maxScale" = "10"
        # Use the VPC Connector
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector.name
        # all egress from the service should go through the VPC Connector
        "run.googleapis.com/vpc-access-egress" = "all-traffic"
        //"run.googleapis.com/ingress" = "all"
        //"run.googleapis.com/allow-unauthenticated" = "true"
      }
    }
  }
}

resource "google_cloud_run_service" "scstore_read_replica" {
  provider = google-beta
  name     = "${var.service_name}--${var.region2}"
  location = var.region2
  project  = var.project_id

  template {
    spec {
      containers {
        image = "us-docker.pkg.dev/qwiklabs-gcp-01-f371c68da851/scstore/scstore-original:1.0.0"

        env {
          name  = "DB_HOSTNAME"
          value = "10.12.2.2"
          #value = google_sql_database_instance.scstore.private_ip_address
        }
        env {
          name  = "DB_PORT"
          value = "5432"
        }
        env {
          name  = "DB_USERNAME"
          value = var.service_name
        }
        env {
          name  = "DB_PASSWORD"
          value = var.service_name
        }
        env {
          name  = "DB_NAME"
          value = var.service_name
        }
        env {
          name  = "GIN_MODE"
          value = "release"
        }
        env {
          name  = "GOOGLE_CLOUD_PROJECT"
          value = var.project_id
        }
      }
    }
    metadata {
      annotations = {
        # Limit scale up to prevent any cost blow outs!
        "autoscaling.knative.dev/minScale" = "1"
        "autoscaling.knative.dev/maxScale" = "10"
        # Use the VPC Connector
        "run.googleapis.com/vpc-access-connector" = google_vpc_access_connector.connector2.name
        # all egress from the service should go through the VPC Connector
        "run.googleapis.com/vpc-access-egress" = "all-traffic"
        //"run.googleapis.com/ingress" = "all"
        //"run.googleapis.com/allow-unauthenticated" = "true"
      }
    }
  }
}

module "lb-http" {
  source  = "GoogleCloudPlatform/lb-http/google//modules/serverless_negs"
  version = "~> 6.3"
  name    = "lb-http-cloudrun"
  project = var.project_id

  ssl                             = false
  managed_ssl_certificate_domains = []
  https_redirect                  = false

  backends = {
    default = {
      description = null


      /*
      groups = [
        for neg in google_compute_region_network_endpoint_group.serverless_neg :
        {
          group = neg.id
        }
      ]
      */

      groups = [
        {
            group = google_compute_region_network_endpoint_group.serverless_neg.id,
            group = google_compute_region_network_endpoint_group.serverless_neg2.id
        }      
      ]
      
      enable_cdn              = true
      security_policy         = null
      custom_request_headers  = null
      custom_response_headers = null

      iap_config = {
        enable               = false
        oauth2_client_id     = ""
        oauth2_client_secret = ""
      }

      log_config = {
        enable      = true
        sample_rate = 1.0
      }
    }
  }
}

resource "google_compute_region_network_endpoint_group" "serverless_neg" {
  name                  = "serverless-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_service.scstore.name
  }
}

resource "google_compute_region_network_endpoint_group" "serverless_neg2" {
  name                  = "serverless-neg"
  network_endpoint_type = "SERVERLESS"
  region                = var.region2
  cloud_run {
    service = google_cloud_run_service.scstore_read_replica.name
  }
}

resource "google_cloud_run_service_iam_member" "public-access" {
  location = google_cloud_run_service.scstore.location
  project  = google_cloud_run_service.scstore.project
  service  = google_cloud_run_service.scstore.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

resource "google_cloud_run_service_iam_member" "public-access-2" {
  location = google_cloud_run_service.scstore_read_replica.location
  project  = google_cloud_run_service.scstore_read_replica.project
  service  = google_cloud_run_service.scstore_read_replica.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Enable Serverless VPC Access Connector API
resource "google_project_service" "vpcaccess_api" {
  service            = "vpcaccess.googleapis.com"
  provider           = google-beta
  disable_on_destroy = false
}

# Enable Service Networking API
resource "google_project_service" "service_networking_api" {
  service            = "servicenetworking.googleapis.com"
  provider           = google-beta
  disable_on_destroy = false
}

locals {
  cidrs = [ 
    { name = "us-central1", cidr = "10.8.0.0/28" },
    { name = "us-east5", cidr = "10.7.0.0/28" }
    #{ name = "us-east1", cidr = "10.6.0.0/28" },
  ]
}

# VPC access connector
/*
resource "google_vpc_access_connector" "connector" {
  for_each      = { for i in local.cidrs : i.name => i }
  name          = "vpc-connector-${each.value.name}"
  provider      = google-beta
  region        = each.value.name
  ip_cidr_range = each.value.cidr
  //max_throughput = 300
  network    = google_compute_network.default.name
  depends_on = [google_project_service.vpcaccess_api]
}
*/

resource "google_vpc_access_connector" "connector" {
  name          = "vpc-connector-${var.region}"
  provider      = google-beta
  region        = var.region
  ip_cidr_range = "10.8.0.0/28"
  //max_throughput = 300
  network    = google_compute_network.default.name
  depends_on = [google_project_service.vpcaccess_api]
}

resource "google_vpc_access_connector" "connector2" {
  name          = "vpc-connector-${var.region2}"
  provider      = google-beta
  region        = var.region2
  ip_cidr_range = "10.7.0.0/28"
  //max_throughput = 300
  network    = google_compute_network.default.name
  depends_on = [google_project_service.vpcaccess_api]
}

/*
# Cloud Router
resource "google_compute_router" "router-vpc-access" {
  for_each = toset(var.regions)
  
  name     = "router-vpc-access"
  provider = google-beta
  region   = each.key
  network  = google_compute_network.default.id
}

# NAT configuration
resource "google_compute_router_nat" "router_nat" {
  for_each = toset(var.regions)

  name                               = "nat"
  provider                           = google-beta
  region                             = each.key
  router                             = google_compute_router.router-vpc-access[each.key].name
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  nat_ip_allocate_option             = "AUTO_ONLY"
}
*/