# Internal (private) IP assigned by the VPC subnet
output "internal_ip" {
  description = "The internal IP address of the VM"
  value       = google_compute_instance.vm.network_interface[0].network_ip
}

# External (NAT) IP — the static IP reserved by google_compute_address
output "external_ip" {
  description = "The external/public IP address of the VM"
  value       = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip
}

# User-defined name set in the resource block
output "vm_name" {
  description = "The name of the VM instance"
  value       = google_compute_instance.vm.name
}

# GCP-computed resource ID (resolves to the same value as self_link in this provider)
output "vm_id" {
  description = "The GCP-computed ID of the VM instance"
  value       = google_compute_instance.vm.id
}

# Full REST API URL — used to reference this resource from other GCP resources
output "vm_self_link" {
  description = "The self_link (full resource URL) of the VM instance"
  value       = google_compute_instance.vm.self_link
}
