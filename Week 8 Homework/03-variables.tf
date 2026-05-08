variable "project_id" {
  description = "The GCP project ID to deploy resources into"
  type        = string
  default     = "dusty-cloud-james-kent"
}

variable "region" {
  description = "GCP region for the provider and static IP"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for the VM instance"
  type        = string
  default     = "us-central1-a"
}
