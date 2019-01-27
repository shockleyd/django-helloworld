variable "name" {
  description = "The name of the cluster"
}

variable "description" {
  description = "Description for the cluster"
  default     = ""
}

variable "region" {
  description = "Name of the region to create the cluster in"
  default     = "us-central1"
}
