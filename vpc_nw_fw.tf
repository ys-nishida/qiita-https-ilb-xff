#####################################################
# VPC setting. Client and service.
#####################################################
resource "google_compute_network" "vpc_client" {
  project                 = local.project.id
  name                    = "vpc-client"
  auto_create_subnetworks = "false"
  routing_mode            = "GLOBAL"
}

resource "google_compute_network" "vpc_service" {
  project                 = local.project.id
  name                    = "vpc-service"
  auto_create_subnetworks = "false"
  routing_mode            = "GLOBAL"
}

#####################################################
# Subnetwork setting in each VPC.
#####################################################
resource "google_compute_subnetwork" "vpc_client_allowed" {
  project       = local.project.id
  network       = google_compute_network.vpc_client.self_link
  name          = "vpc-client-allowed-tky-192-128-0"
  ip_cidr_range = "192.168.0.0/24"
  region        = local.base_region
}

resource "google_compute_subnetwork" "vpc_client_denied" {
  project       = local.project.id
  network       = google_compute_network.vpc_client.self_link
  name          = "vpc-client-denied-tky-192-128-0"
  ip_cidr_range = "192.168.128.0/24"
  region        = local.base_region
}

resource "google_compute_subnetwork" "vpc_service" {
  project       = local.project.id
  network       = google_compute_network.vpc_service.self_link
  name          = "vpc-service-tky-10-0-0"
  ip_cidr_range = "10.0.0.0/24"
  region        = local.base_region
}

resource "google_compute_subnetwork" "vpc_service_ilb_proxy" {
  provider      = google-beta
  project       = local.project.id
  network       = google_compute_network.vpc_service.self_link
  name          = "vpc-service-ilb-proxy-tky-172-16-0"
  ip_cidr_range = "172.16.0.0/24"
  region        = local.base_region

  purpose = "INTERNAL_HTTPS_LOAD_BALANCER"
  role    = "ACTIVE"
}

#####################################################
# VPC Peering.
#####################################################
resource "google_compute_network_peering" "vpc_client_to_service" {
  name                 = "peer-client-to-service"
  network              = google_compute_network.vpc_client.self_link
  peer_network         = google_compute_network.vpc_service.self_link
  export_custom_routes = false
  import_custom_routes = false
}

resource "google_compute_network_peering" "vpc_service_to_client" {
  name                 = "peer-service-to-client"
  network              = google_compute_network.vpc_service.self_link
  peer_network         = google_compute_network.vpc_client.self_link
  export_custom_routes = false
  import_custom_routes = false
}

#####################################################
# Firewall rules in each VPC.
#####################################################
resource "google_compute_firewall" "vpc_service_allow_healthcheck" {
  project = local.project.id
  name    = "vpc-service-allow-healthcheck"

  network   = google_compute_network.vpc_service.self_link
  direction = "INGRESS"
  priority  = "1000"

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["35.191.0.0/16", "130.211.0.0/22"]
  target_tags   = google_compute_instance.rproxy_nginx.tags
}

resource "google_compute_firewall" "vpc_service_allow_proxy_nginx" {
  project = local.project.id
  name    = "vpc-service-allow-proxy-nginx"

  network   = google_compute_network.vpc_service.self_link
  direction = "INGRESS"
  priority  = "1000"

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = [google_compute_subnetwork.vpc_service_ilb_proxy.ip_cidr_range]
  target_tags   = google_compute_instance.rproxy_nginx.tags
}

resource "google_compute_firewall" "vpc_client_allow_external_iap" {
  project = local.project.id
  name    = "vpc-client-allow-external-iap"

  network   = google_compute_network.vpc_client.self_link
  direction = "INGRESS"
  priority  = "2000"

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
}

resource "google_compute_firewall" "vpc_service_allow_external_iap" {
  project = local.project.id
  name    = "vpc-service-allow-external-iap"

  network   = google_compute_network.vpc_service.self_link
  direction = "INGRESS"
  priority  = "2000"

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
}