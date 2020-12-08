resource "google_storage_bucket" "rproxy_nginx_conf" {
  project       = local.project.id
  name          = "<bucket name>"
  storage_class = "MULTI_REGIONAL"
  location      = "asia"
}

resource "google_storage_bucket_object" "rproxy_nginx_conf" {
  name   = "nginx.conf"
  source = "./rproxy-nginx-conf/nginx.conf"
  bucket = google_storage_bucket.rproxy_nginx_conf.name
}

resource "google_storage_bucket_object" "rproxy_nginx_conf_allow_ip_map" {
  name   = "allow_ip_map.conf"
  source = "./rproxy-nginx-conf/allow_ip_map.conf"
  bucket = google_storage_bucket.rproxy_nginx_conf.name
}

resource "google_storage_bucket_object" "testapp" {
  name   = "testapp.py"
  source = "./rproxy-nginx-conf/testapp.py"
  bucket = google_storage_bucket.rproxy_nginx_conf.name
}