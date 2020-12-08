provider "google" {
  version = "~> 3"
  project = local.project.id
  region  = local.base_region
}
provider "google-beta" {
  version = "~> 3"
  project = local.project.id
  region  = local.base_region
}