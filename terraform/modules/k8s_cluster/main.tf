resource "google_container_cluster" "primary" {
  name               = "${var.name}"
  description        = "${var.description}"
  region             = "${var.region}"
  initial_node_count = 1

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  # disable basic auth and client certificate
  master_auth {
    password = ""
    username = ""
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  ip_allocation_policy {
    # this enables vpc-native without having to create/specify subnet ranges
    create_subnetwork = true
  }
}
