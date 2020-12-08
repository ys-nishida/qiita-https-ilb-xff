resource "google_compute_instance" "client_allowed" {
  name         = "client-allowed"
  machine_type = "e2-micro"
  project      = local.project.id
  zone         = local.base_zone
  tags         = ["client"]

  boot_disk {
    auto_delete = true
    source      = google_compute_disk.client_allowed.self_link
  }

  network_interface {
    subnetwork_project = local.project.id
    subnetwork         = google_compute_subnetwork.vpc_client_allowed.self_link
  }

  metadata = {
    enable-oslogin = "true"
  }
}

resource "google_compute_disk" "client_allowed" {
  name    = "client-disk-allowed"
  project = local.project.id
  zone    = local.base_zone
  size    = 20
  type    = "pd-standard"
  image   = "centos-cloud/centos-8"
}

resource "google_compute_instance" "client_denied" {
  name         = "client-denied"
  machine_type = "e2-micro"
  project      = local.project.id
  zone         = local.base_zone
  tags         = ["client"]

  boot_disk {
    auto_delete = true
    source      = google_compute_disk.client_denied.self_link
  }

  network_interface {
    subnetwork_project = local.project.id
    subnetwork         = google_compute_subnetwork.vpc_client_denied.self_link
  }

  metadata = {
    enable-oslogin = "true"
  }
}

resource "google_compute_disk" "client_denied" {
  name    = "client-disk-denied"
  project = local.project.id
  zone    = local.base_zone
  size    = 20
  type    = "pd-standard"
  image   = "centos-cloud/centos-8"
}