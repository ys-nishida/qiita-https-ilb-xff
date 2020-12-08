resource "google_compute_instance" "rproxy_nginx" {
  name         = "rproxy-nginx"
  machine_type = "e2-micro"
  project      = local.project.id
  zone         = local.base_zone
  tags         = ["rproxy-nginx"]

  boot_disk {
    auto_delete = true
    source      = google_compute_disk.rproxy_nginx.self_link
  }

  network_interface {
    subnetwork_project = local.project.id
    subnetwork         = google_compute_subnetwork.vpc_service.self_link
  }

  metadata = {
    enable-oslogin = "true"
  }
  metadata_startup_script = file("./rproxy-nginx-conf/startup.sh")

  service_account {
    scopes = ["storage-ro"]
  }

  depends_on = [
    google_storage_bucket_object.rproxy_nginx_conf,
    google_storage_bucket_object.rproxy_nginx_conf_allow_ip_map,
    google_storage_bucket_object.testapp
  ]
}

resource "google_compute_disk" "rproxy_nginx" {
  project = local.project.id
  name    = "rproxy-nginx-disk"
  zone    = local.base_zone
  size    = 20
  type    = "pd-standard"
  image   = "centos-cloud/centos-8"
}

resource "google_compute_instance_group" "rproxy_nginx" {
  name        = "rproxy-nginx-grp"
  description = "Reverse proxy nginx unmanaged instance group"
  zone        = local.base_zone

  instances = [
    google_compute_instance.rproxy_nginx.id,
  ]

  named_port {
    name = "http"
    port = "80"
  }
}

resource "google_compute_region_health_check" "rproxy_nginx_hc" {
  project             = local.project.id
  name                = "rproxy-nginx-hc"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10 # 50 seconds

  http_health_check {
    request_path = "/health"
    port         = "80"
  }
}

resource "google_compute_region_backend_service" "rproxy_nginx_backend_svc" {
  region = local.base_region
  name   = "rproxy-nginx-backend"

  load_balancing_scheme = "INTERNAL_MANAGED"
  locality_lb_policy    = "ROUND_ROBIN"

  backend {
    group           = google_compute_instance_group.rproxy_nginx.self_link
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
    max_utilization = 0.8
  }

  protocol    = "HTTP"
  timeout_sec = 10

  health_checks = [google_compute_region_health_check.rproxy_nginx_hc.self_link]
}

resource "google_compute_region_url_map" "rproxy_nginx_url_map" {
  region          = local.base_region
  name            = "rproxy-nginx-ilb"
  default_service = google_compute_region_backend_service.rproxy_nginx_backend_svc.self_link
}

resource "google_compute_region_target_https_proxy" "rproxy_nginx_https_proxy" {
  region           = local.base_region
  name             = "rproxy-nginx-https-proxy"
  url_map          = google_compute_region_url_map.rproxy_nginx_url_map.self_link
  ssl_certificates = ["test-ssl-cert"]
}

resource "google_compute_forwarding_rule" "rproxy_nginx_forwarding_rule" {
  region = local.base_region
  name   = "rproxy-nginx-forwarding-rule"

  network    = google_compute_network.vpc_service.self_link
  subnetwork = google_compute_subnetwork.vpc_service.self_link
  network_tier          = "PREMIUM"
  load_balancing_scheme = "INTERNAL_MANAGED"
  ip_protocol           = "TCP"
  port_range            = "443-443"
  target                = google_compute_region_target_https_proxy.rproxy_nginx_https_proxy.self_link
}