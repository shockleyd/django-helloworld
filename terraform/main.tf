provider "google" {
  credentials = "${file("${var.credentials_path}")}"
  project     = "${var.project_id}"
  region      = "${var.default_region}"
}

module "k8s_cluster" {
  source        = "modules/k8s_cluster"
  name          = "${var.k8s_cluster_name}"
  description   = "K8s cluster to demo CI/CD with CircleCI"
}
