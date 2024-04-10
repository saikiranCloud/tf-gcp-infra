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

# Create firewall rule to allow traffic only from load balancer's source IP ranges
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
  depends_on = [ google_compute_global_forwarding_rule.lb_forwarding_rule ]
  source_ranges = [google_compute_global_forwarding_rule.lb_forwarding_rule.ip_address]
  target_tags   = ["webapp"]
}

resource "google_compute_firewall" "allow_health_traffic" {
  project = var.project_id
  name    = "allow-health-traffic"
  network = google_compute_network.vpc.self_link
  priority    = var.priority_allow
  allow {
    protocol = "tcp"
    ports    = [var.application_port]
  }
  depends_on = [ google_compute_global_forwarding_rule.lb_forwarding_rule ]
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
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

# resource "google_compute_instance" "custom-instance" {
#   project = var.project_id
#   name         = var.instance_name
#   machine_type = var.machine_type
#   zone         = var.zone
#   boot_disk {
#     initialize_params {
#       type  = var.type
#       size  = var.size
#       image = var.image_name
#     }
#   }

#   service_account {
#     email  = google_service_account.vm_service_account.email
#     scopes = ["https://www.googleapis.com/auth/cloud-platform",
#     "https://www.googleapis.com/auth/logging.write",
#     "https://www.googleapis.com/auth/logging.admin"]
#   }

#   # metadata_startup_script = file("startup-script.sh")
#   # metadata_startup_script = "${data.template_file.init.rendered}"
#   metadata_startup_script = <<-EOT
# echo "DB_USER=${google_sql_user.user.name}" >> /opt/webapp/.env \
# echo "DB_PASSWORD=${google_sql_user.user.password}" >> /opt/webapp/.env \
# echo "DB_NAME=${google_sql_database.database.name}" >> /opt/webapp/.env \
# echo "DB_INSTANCE_NAME=${google_sql_database_instance.instance.connection_name}" >> /opt/webapp/.env \
# echo "DB_HOST=\"${google_sql_database_instance.instance.private_ip_address}\"" >> /opt/webapp/.env \
# echo "PROJECT_ID=\"${var.project_id}\"" >> /opt/webapp/.env \
# sleep 20
# sudo systemctl restart webapp
# EOT

#   network_interface {
#     network = google_compute_network.vpc.self_link
#     subnetwork = google_compute_subnetwork.webapp_subnet.self_link  
#     access_config {   
#     }
#   }
#   tags = ["webapp"]
#   depends_on = [ 
#     google_service_account.vm_service_account,
#     google_project_iam_binding.metric_writer_binding,
#     google_project_iam_binding.logs_admin_binding,
#     google_sql_database.database, 
#     google_sql_database_instance.instance,
#     google_sql_user.user ]
# }
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
  encryption_key_name = google_kms_crypto_key.sql_key.id									  																					   
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
  special = false
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
    google_compute_global_forwarding_rule.lb_forwarding_rule.ip_address,
    # google_compute_instance.custom-instance.network_interface.0.access_config.0.nat_ip, 
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
  depends_on = [ google_kms_crypto_key_iam_binding.project ]
  encryption {
    default_kms_key_name = google_kms_crypto_key.store_key.id
  }
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
  depends_on = [ data.archive_file.serverlesszip,google_storage_bucket.sai-bucket,google_vpc_access_connector.cloud_function_connector ]
}

resource "google_service_account" "instance_template_sa" {
  project = var.project_id
  account_id   =  var.instance_template_sa_aid
  display_name =  var.instance_template_sa_dn
}
resource "google_service_account" "webapp_health_check_sa" {
  project = var.project_id
  account_id   =  var.webapp_health_check_sa_aid
  display_name =  var.webapp_health_check_sa_dn
}

# Create a regional compute instance template
resource "google_compute_region_instance_template" "webapp_instance_template" {
  project       = var.project_id
  region = var.region
  name          = var.template_name
  description   = var.template_dn
  machine_type  = var.machine_type
  tags          = var.template_tags
  disk {
    source_image = var.image_name
    boot         = var.template_boot
    disk_size_gb = var.size
    disk_type = var.type
    source_image_encryption_key {
      kms_key_self_link = google_kms_crypto_key.vm_key.id
    }
  }
  network_interface {
    network = google_compute_network.vpc.self_link
    subnetwork = google_compute_subnetwork.webapp_subnet.self_link
    access_config {}
  }
  lifecycle {
    create_before_destroy = true
  }
  service_account {
    email  = google_service_account.vm_service_account.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/logging.admin"]
  }
  metadata_startup_script = <<-EOT
echo "DB_USER=${google_sql_user.user.name}" >> /opt/webapp/.env \
echo "DB_PASSWORD=${google_sql_user.user.password}" >> /opt/webapp/.env \
echo "DB_NAME=${google_sql_database.database.name}" >> /opt/webapp/.env \
echo "DB_INSTANCE_NAME=${google_sql_database_instance.instance.connection_name}" >> /opt/webapp/.env \
echo "DB_HOST=\"${google_sql_database_instance.instance.private_ip_address}\"" >> /opt/webapp/.env \
echo "PROJECT_ID=\"${var.project_id}\"" >> /opt/webapp/.env \
EOT
  depends_on = [ 
    google_service_account.vm_service_account,
    google_project_iam_binding.metric_writer_binding,
    google_project_iam_binding.logs_admin_binding,
    google_sql_database.database, 
    google_sql_database_instance.instance,
    google_sql_user.user ]
}
# Create a compute health check
resource "google_compute_health_check" "webapp_health_check" {
  project      = var.project_id
  name         = var.health_check_name
  check_interval_sec = var.health_checkinterval
  timeout_sec  = var.health_checktimeout
  http_health_check {
    port = var.application_port
    port_name = var.health_check_portname
    request_path = var.health_check_request_path
  }
  }
resource "google_service_account" "autoscaler_sa" {
  project = var.project_id
  account_id   =  var.autoscaler_sa_aid
  display_name =  var.autoscaler_sa_dn
}
resource "google_compute_region_autoscaler" "webapp_autoscaler" {
  project         = var.project_id
  region = var.region
  name            = var.autoscaler_name
  target          = google_compute_region_instance_group_manager.webapp_group_manager.self_link
  autoscaling_policy {
    min_replicas = var.autoscaler_min
    max_replicas = var.autoscaler_max
    cpu_utilization {
      target = var.autoscaler_cpu
    }
  }
  depends_on = [ google_compute_region_instance_group_manager.webapp_group_manager ]
}

# Create a regional compute instance group manager
resource "google_compute_region_instance_group_manager" "webapp_group_manager" {
  version {
    instance_template   = google_compute_region_instance_template.webapp_instance_template.self_link
  }
  project             = var.project_id
  region              = var.region
  name                = var.igm_name
  base_instance_name  = var.igm_base_name
  target_size         = var.igm_target_size
  named_port {
    name = var.igm_port_name
    port = var.application_port
  }
  distribution_policy_zones = var.distribution_policy_zones
  auto_healing_policies {
    initial_delay_sec = var.igm_delay
    health_check = google_compute_health_check.webapp_health_check.self_link
  }
  # target_pools = [google_compute_target_pool.webapp_target_pool.self_link]
}
# Retrieve the source IP ranges of the load balancer
data "google_compute_global_forwarding_rule" "lb_forwarding_rule" {
  project = var.project_id
  name = google_compute_global_forwarding_rule.lb_forwarding_rule.name
}
# Create a Google-managed SSL certificate
resource "google_compute_managed_ssl_certificate" "lb_default" {
  provider = google-beta
  name     = var.ssl_name
  managed {
    domains = var.ssl_domain
  }
}

# Create an external HTTP(S) load balancer
resource "google_compute_global_forwarding_rule" "lb_forwarding_rule" {
  name       = var.global_forwarding_name
  project    = var.project_id
  target     = google_compute_target_https_proxy.lb_target_proxy.self_link
  port_range = var.global_forwarding_port_range
  load_balancing_scheme = var.global_forwarding_scheme
  # ip_address = 
  ip_protocol = var.global_forwarding_ip_protocol
}

# Create a target HTTPS proxy
resource "google_compute_target_https_proxy" "lb_target_proxy" {
  name        = var.https_proxy_name
  project     = var.project_id
  url_map     = google_compute_url_map.lb_url_map.self_link
  ssl_certificates = [google_compute_managed_ssl_certificate.lb_default.self_link]
  depends_on = [ google_compute_managed_ssl_certificate.lb_default ]
}

# Create a URL map
resource "google_compute_url_map" "lb_url_map" {
  name    = var.url_map_name
  project = var.project_id
  default_service = google_compute_backend_service.lb_backend_service.self_link
}

# Create a backend service
resource "google_compute_backend_service" "lb_backend_service" {
  name           = var.lb_backend_name
  project        = var.project_id
  health_checks = [google_compute_health_check.webapp_health_check.self_link]
  enable_cdn     = var.lb_backend_enable_cdn
  port_name      = var.lb_backend_port_name
  protocol = var.lb_backend_protocol
  backend {
    group           = google_compute_region_instance_group_manager.webapp_group_manager.instance_group
    balancing_mode  = var.lb_backend_balancing_mode
    capacity_scaler = var.lb_backend_capacity_scaler
  }
}

data "google_project" "current" {
  project_id = var.project_id
}
locals {
    cloud_storage_service_account = "service-${data.google_project.current.number}@gs-project-accounts.iam.gserviceaccount.com"
}

resource "google_project_service_identity" "gcp_sa_cloud_sql" {
  provider = google-beta
  service  = var.sqlapis
}

resource "google_kms_key_ring" "key_ring" {
  provider = google-beta
  project =  var.project_id
  name     = var.keyring_name
  location = var.region
}
resource "google_kms_crypto_key" "vm_key" {
  name      = var.vmkey_name
  key_ring  = google_kms_key_ring.key_ring.id
  purpose   = var.purpose
  rotation_period = var.key_rotation_period
}
resource "google_kms_crypto_key" "sql_key" {
  name      = var.sqlkey_name
  key_ring  = google_kms_key_ring.key_ring.id
  purpose   = var.purpose
  rotation_period = var.key_rotation_period
}
resource "google_kms_crypto_key" "store_key" {
  name      = var.storekey_name
  key_ring  = google_kms_key_ring.key_ring.id
  purpose   = var.purpose
  rotation_period = var.key_rotation_period
}

resource "google_kms_crypto_key_iam_binding" "crypto_key" {
  provider      = google-beta
  crypto_key_id = google_kms_crypto_key.sql_key.id
  role          = var.kms_role
  members = [
    "serviceAccount:${google_project_service_identity.gcp_sa_cloud_sql.email}",
  ]
}

resource "google_kms_crypto_key_iam_binding" "crypto_vm_key" {
  provider      = google-beta
  crypto_key_id = google_kms_crypto_key.vm_key.id
  role          = var.kms_role  
  members = [
  "serviceAccount:${data.google_project.current.number}@cloudservices.gserviceaccount.com",
  "serviceAccount:${data.google_project.current.number}-compute@developer.gserviceaccount.com", 
  "serviceAccount:service-${data.google_project.current.number}@compute-system.iam.gserviceaccount.com"]
}
resource "google_kms_crypto_key_iam_binding" "project" {
  provider = google-beta
  crypto_key_id = google_kms_crypto_key.store_key.id
  role    = var.kms_role
  members = [
    "serviceAccount:service-${data.google_project.current.number}@gs-project-accounts.iam.gserviceaccount.com"
  ]
}
