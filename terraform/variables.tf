variable "project_id" {
  description = "Name/id of the project"
}

variable "credentials_path" {
  description = "Path to local credentials file (json) for google cloud"
}

variable "default_region" {
  description = "Default region to create resources in"
  default     = "us-central1"
}

variable "k8s_cluster_name" {
  description = "Name of the K8s cluster to create"
}