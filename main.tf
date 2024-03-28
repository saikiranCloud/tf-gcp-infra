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


resource "google_service_account" "vm_service_account" {
  project = var.project_id
  account_id   = var.sa_acc_id
  display_name = var.sa_display_name
}

resource "google_project_iam_binding" "logs_admin_binding" {
  project = var.project_id
  role    = "roles/logging.admin"
  
  members = [
    "serviceAccount:${google_service_account.vm_service_account.email}"
  ]
}

resource "google_project_iam_binding" "metric_writer_binding" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  
  members = [
    "serviceAccount:${google_service_account.vm_service_account.email}"
  ]
}

resource "google_project_iam_binding" "vm_pubsub_publisher_binding" {
  project = var.project_id
  role    = "roles/pubsub.publisher"

  members = [
    "serviceAccount:${google_service_account.vm_service_account.email}"
  ]
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

  service_account {
    email  = google_service_account.vm_service_account.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/logging.admin"]
  }

  # metadata_startup_script = file("startup-script.sh")
  # metadata_startup_script = "${data.template_file.init.rendered}"
  metadata_startup_script = <<-EOT
echo "DB_USER=${google_sql_user.user.name}" >> /opt/webapp/.env \
echo "DB_PASSWORD=${google_sql_user.user.password}" >> /opt/webapp/.env \
echo "DB_NAME=${google_sql_database.database.name}" >> /opt/webapp/.env \
echo "DB_INSTANCE_NAME=${google_sql_database_instance.instance.connection_name}" >> /opt/webapp/.env \
echo "DB_HOST=\"${google_sql_database_instance.instance.private_ip_address}\"" >> /opt/webapp/.env \
echo "PROJECT_ID=\"${var.project_id}\"" >> /opt/webapp/.env \
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
  depends_on = [ 
    google_service_account.vm_service_account,
    google_project_iam_binding.metric_writer_binding,
    google_project_iam_binding.logs_admin_binding,
    google_sql_database.database, 
    google_sql_database_instance.instance,
    google_sql_user.user ]
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
  network                = google_compute_network.vpc.self_link
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

# Resource to create Cloud DNS record set pointing to the VM instance
resource "google_dns_record_set" "webapp_dns_record" {
  provider = google-beta
  project  = var.project_id
  name     = var.dns_name
  type     = var.a_record
  ttl      = var.a_record_ttl
  managed_zone = var.dns_zone

  rrdatas = [
    google_compute_instance.custom-instance.network_interface.0.access_config.0.nat_ip, 
  ]
}

# Create Pub/Sub topic
resource "google_pubsub_topic" "verify_email_topic" {
  project = var.project_id
  name =  var.topic_name
  message_retention_duration = var.msg_duration
}

# Create Service Account for pubsub
resource "google_service_account" "pubsub_sa" {
  project = var.project_id
  account_id   =  var.pubsub_sa_account_id
  display_name =  var.pubsub_sa_name
}

# Create IAM binding for the Service Account
resource "google_project_iam_binding" "pubsub_sa_binding" {
  project = var.project_id
  role    = var.pubsub_sa_binding_role

  members = [
    "serviceAccount:${google_service_account.pubsub_sa.email}",
  ]
}

resource "google_service_account" "pubsub_sub_sa" {
  project = var.project_id
  account_id   =  var.pubsub_sub_sa_account_id
  display_name =  var.pubsub_sub_sa_display_name
}

# Create Pub/Sub subscription for the Cloud Function
resource "google_pubsub_subscription" "verify_email_subscription" {
  project = var.project_id
  name  = var.verify_email_subscription_name
  topic = google_pubsub_topic.verify_email_topic.name
  # ack_deadline_seconds = 10
}

# Create IAM binding for the Service Account
resource "google_project_iam_binding" "pubsub_sub_sa_binding" {
  project = var.project_id
  role    = "roles/pubsub.subscriber"

  members = [
    "serviceAccount:${google_service_account.pubsub_sub_sa.email}",
  ]
}

resource "google_vpc_access_connector" "cloud_function_connector" {
  project = var.project_id
  name            =  var.cloud_function_connector_name
  region          = var.region
  network         = google_compute_network.vpc.name
  ip_cidr_range   = var.cloud_function_connector_cidr
  min_throughput= var.cloud_function_connector_throughput
}


resource "google_service_account" "cloudfunction_sa" {
  project = var.project_id
  account_id   =  var.cloudfunction_sa_aid
  display_name =  var.cloudfunction_sa_dn
}
resource "google_cloudfunctions2_function_iam_binding" "binding" {
  project = var.project_id
  location = var.region
  cloud_function = google_cloudfunctions2_function.cloud_function.name
  role = "roles/cloudfunctions.invoker"
  members = [
    "serviceAccount:${google_service_account.cloudfunction_sa.email}",
  ]
  depends_on = [ google_cloudfunctions2_function.cloud_function ]
}

data "archive_file" "serverlesszip" {
  type = var.datatype
  source_dir =  var.datasource
  output_path =   var.dataop
}
resource "google_storage_bucket_object" "zip" {
  source = data.archive_file.serverlesszip.output_path
  content_type =  var.obj_content_type
  name = var.bucket_obj_name
  bucket = google_storage_bucket.sai-bucket.name
  depends_on = [ google_storage_bucket.sai-bucket, data.archive_file.serverlesszip]
}

resource "random_id" "bucket_prefix" {
  byte_length = 8
}

resource "google_storage_bucket" "sai-bucket" {
  project = var.project_id
  name = "${random_id.bucket_prefix.hex}-new-bucket"
  location = var.region
}

resource "google_cloudfunctions2_function" "cloud_function" {
  project = var.project_id
  name = var.gcf_name
  location = var.region
  description = "Cloud function" 
  build_config {
    runtime = var.gcf_runtime
    entry_point = var.gcf_ep
    source {
      storage_source {
        bucket = google_storage_bucket.sai-bucket.name
        object = google_storage_bucket_object.zip.name
      }
    }
  }
  event_trigger {
    event_type = var.trig_event_type
    trigger_region = var.region
    pubsub_topic = google_pubsub_topic.verify_email_topic.id
    retry_policy = var.trig_retry_policy
  }
  service_config {
    max_instance_count = var.sc_instance_count
    available_memory = var.sc_memory
    timeout_seconds = var.sc_timeout_seconds
    service_account_email = google_service_account.cloudfunction_sa.email
    vpc_connector = google_vpc_access_connector.cloud_function_connector.name
    environment_variables = {
      MAILGUN_DOMAIN = var.mg_domain
      MAILGUN_API_KEY = var.mg_api
      DB_USER = google_sql_user.user.name
      DB_PASSWORD = google_sql_user.user.password
      DB_NAME = google_sql_database.database.name
      DB_HOST = google_sql_database_instance.instance.private_ip_address
      PROJECT_ID = var.project_id
    }
  } 
  depends_on = [ data.archive_file.serverlesszip,google_storage_bucket.sai-bucket ]
}
