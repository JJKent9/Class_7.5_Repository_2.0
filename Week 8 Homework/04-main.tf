# Reserve a static external IP address for the VM
#resource "google_compute_address" "vm_ip" {
# name   = "hw-vm-external-ip"
# region = var.region
#}

# CentOS Stream 10 VM in the default VPC
# Image family: centos-stream-10 (project: centos-cloud)
# Machine type: N2 series — good balance of compute and cost
# Disk: 100 GB pd-balanced boot disk
resource "google_compute_instance" "vm" {
  name         = "hw-web-vm"
  machine_type = "n2-standard-2"
  zone         = var.zone

  # "http-server" tag opens port 80 via the default-allow-http firewall rule
  tags = ["http-server"]

  boot_disk {
    initialize_params {
      #when Terraform makes a new server, it automatically grabs the newest updated version instead of an outdated one.      image = "centos-cloud/centos-stream-10"
      size = 100 # GB
      type = "pd-balanced"
    }
  }

  network_interface {
    network = "default"

    access_config {}
  }


  metadata_startup_script = file("${path.module}/startup.sh")

}