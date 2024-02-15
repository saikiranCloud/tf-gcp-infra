provider "google" {
  credentials = file("./credentials/tf-gcp-infra.json")
  project     = var.project
  region      = var.region
}

# https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_network#delete_default_routes_on_create

resource "google_compute_network" "vpc" {
  name                    = "vpc"
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "webapp" {
  name          = "webapp"
  ip_cidr_range = "10.0.6.0/24"
  network       = google_compute_network.vpc.self_link
}

resource "google_compute_subnetwork" "db" {
  name          = "db"
  ip_cidr_range = "10.0.7.0/24"
  network       = google_compute_network.vpc.self_link
}

resource "google_compute_route" "webapp_route" {
  name                  = "webapp-route"
  network               = google_compute_network.vpc.self_link
  dest_range            = "0.0.0.0/0"
  next_hop_gateway      = "default-internet-gateway"
  priority              = 1000
}
