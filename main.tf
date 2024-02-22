# Provider configuration for GCP
provider "google" {
  project = var.project_id
  region  = var.region
}

# Resource to create VPC
resource "google_compute_network" "vpc" {
  name                            = var.vpc_name
  auto_create_subnetworks         = var.auto_create_subnetworks
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = var.delete_default_routes_on_create
}

#Resource to create subnet named webapp
resource "google_compute_subnetwork" "webapp_subnet" {
  name          = var.webapp_subnet_name
  region        = var.region
  network       = google_compute_network.vpc.self_link
  ip_cidr_range = var.webapp_subnet_cidr
}

#Resource to create subnet named db
resource "google_compute_subnetwork" "db_subnet" {
  name          = var.db_subnet_name
  region        = var.region
  network       = google_compute_network.vpc.self_link
  ip_cidr_range = var.db_subnet_cidr
}

# Resource to create route for webapp subnet
resource "google_compute_route" "vpc_route" {
  name             = var.vpc_route_name
  network          = google_compute_network.vpc.self_link
  dest_range       = var.route_range
  next_hop_gateway = var.next_hop_gateway
}

# Resource to create firewall rule allowing application traffic
resource "google_compute_firewall" "allow_app_traffic" {
  name    = "allow-app-traffic"
  network = google_compute_network.vpc.self_link
  priority    = var.priority_allow
  allow {
    protocol = "tcp"
    ports    = [var.application_port]
  }
  
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["webapp"]
}

# Resource to create firewall rule denying incoming SSH traffic
resource "google_compute_firewall" "deny_ssh" {
  name    = "deny-ssh"
  network = google_compute_network.vpc.self_link
  priority    = var.priority_deny

  deny {
    protocol = "tcp"
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["webapp"]
}

resource "google_compute_instance" "custom_instance" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  boot_disk {
    initialize_params {
      type  = var.type
      size  = var.size
      image = var.image_name
    }
  }
  network_interface {
    network = var.vpc_name
    subnetwork = var.webapp_subnet_name
  
  }

  network_interface {
    network = google_compute_network.vpc.self_link
    subnetwork = google_compute_subnetwork.webapp_subnet.self_link  
    access_config {   
    }
  }
  tags = ["webapp"]
}