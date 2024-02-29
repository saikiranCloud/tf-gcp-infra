# Provider configuration for GCP
provider "google-beta" {
  project = var.project_id
  region  = var.region
}

# Resource to create VPC
resource "google_compute_network" "vpc" {
  project = var.project_id
  name                            = var.vpc_name
  auto_create_subnetworks         = var.auto_create_subnetworks
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = var.delete_default_routes_on_create
}

#Resource to create subnet named webapp
resource "google_compute_subnetwork" "webapp_subnet" {
  project = var.project_id
  name          = var.webapp_subnet_name
  region        = var.region
  network       = google_compute_network.vpc.self_link
  ip_cidr_range = var.webapp_subnet_cidr
  private_ip_google_access = true
}

#Resource to create subnet named db
resource "google_compute_subnetwork" "db_subnet" {
  project = var.project_id
  name          = var.db_subnet_name
  region        = var.region
  network       = google_compute_network.vpc.self_link
  ip_cidr_range = var.db_subnet_cidr
  private_ip_google_access = true
}

# Resource to create route for webapp subnet
resource "google_compute_route" "vpc_route" {
  project = var.project_id
  name             = var.vpc_route_name
  network          = google_compute_network.vpc.self_link
  dest_range       = var.route_range
  next_hop_gateway = var.next_hop_gateway
}

# Resource to create firewall rule allowing application traffic
resource "google_compute_firewall" "allow_app_traffic" {
  project = var.project_id
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
  project = var.project_id
  name    = "deny-ssh"
  network = google_compute_network.vpc.self_link
  priority    = var.priority_deny

  deny {
    protocol = "tcp"
    ports = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["webapp"]
}
resource "google_compute_instance" "custom-instance" {
  project = var.project_id
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
  # metadata_startup_script = file("startup-script.sh")
  # metadata_startup_script = "${data.template_file.init.rendered}"
  metadata_startup_script = <<-EOT
echo "DB_USER=${google_sql_user.user.name}" >> /opt/webapp/.env \
echo "DB_PASSWORD=${google_sql_user.user.password}" >> /opt/webapp/.env \
echo "DB_NAME=${google_sql_database.database.name}" >> /opt/webapp/.env \
echo "DB_INSTANCE_NAME=${google_sql_database_instance.instance.connection_name}" >> /opt/webapp/.env \
echo "DB_HOST=\"${google_sql_database_instance.instance.private_ip_address}\"" >> /opt/webapp/.env \
sleep 20
sudo systemctl restart webapp
EOT

  network_interface {
    network = google_compute_network.vpc.self_link
    subnetwork = google_compute_subnetwork.webapp_subnet.self_link  
    access_config {   
    }
  }
  tags = ["webapp"]
  depends_on = [ google_sql_database.database, google_sql_database_instance.instance,google_sql_user.user ]
}
resource "google_compute_global_address" "default" {
  project      = var.project_id
  name         = var.global_address
  address_type = var.global_address_type
  purpose      = var.global_address_purpose 
  network      = google_compute_network.vpc.self_link
  prefix_length = var.global_address_length 
}
resource "google_service_networking_connection" "private_vpc_connection" {
  network               = google_compute_network.vpc.self_link
  service                 = "servicenetworking.googleapis.com"														  
  reserved_peering_ranges = [google_compute_global_address.default.name]
}

resource "google_sql_database_instance" "instance" {
  name                = var.db-instance-name
  region              = var.db-instance-region
  deletion_protection = var.db-instance-deletion-protection
  database_version    = var.db-instance-database-version
  project             = var.project_id
  depends_on = [google_service_networking_connection.private_vpc_connection]									  																					   
  settings {
    tier              = var.instance_tier  
    edition             = var.instance_edition  
    availability_type = var.db-instance-availability
    disk_type         = var.db-instance-disk-type
    disk_size         = var.db-instance-disk-size
    backup_configuration {
      enabled = var.instance_enabled             
      binary_log_enabled = var.instance_log_enabled        
    }
    ip_configuration {
      ipv4_enabled = var.db-instance-ipv4-enabled
      private_network = google_compute_network.vpc.self_link
    }
  }
}

resource "google_sql_database" "database" {
  project  = var.project_id
  name     = var.google-sql-database-name
  instance = google_sql_database_instance.instance.name
}
resource "random_password" "webapp_password" {
  length  = 16
  special = true
}

resource "google_sql_user" "user" {
  project  = var.project_id
  name     = var.google-sql-database-user
  instance = google_sql_database_instance.instance.name
  password = random_password.webapp_password.result
}