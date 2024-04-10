variable "project_id" {
  description = "The ID of the GCP project"
}
variable "region" {
  description = "The region for the resources"
}

variable "vpc_name" {
  description = "Name of the VPC"
}

variable "auto_create_subnetworks" {
  description = "Boolean value to not create subnetworks"
}

variable "delete_default_routes_on_create" {
  description = "Boolean value to delete default routes on create"
}

variable "webapp_subnet_name" {
  description = "Name of the webapp subnet"
}

variable "db_subnet_name" {
  description = "Name of the db subnet"
}

variable "webapp_subnet_cidr" {
  description = "CIDR range for the webapp subnet"
}

variable "db_subnet_cidr" {
  description = "CIDR range for the db subnet"
}

variable "vpc_route_name" {
  description = "Name of the vpc route"
}

variable "routing_mode" {
  description = "Name of the routing mode"
}

variable "route_range" {
  description = "Range for the webapp subnet route"
}

variable "next_hop_gateway" {
  description = "value for next_hop_gateway"
}

variable "application_port" {
  description = "value for next_hop_gateway"
}

variable "instance_name" {
  description = "value for instance"
}

variable "machine_type" {
  description = "value for machine_type"
}

variable "zone" {
  description = "value for zone"
}

variable "image_name" {
  description = "value for image_name"
}
variable "size" {
  description = "value for size"
}
variable "type" {
  description = "value for size"
}
variable "priority_allow" {
  description = "value for allow"
}
variable "priority_deny" {
  description = "value for priority_deny"
}


variable "db-instance-name" {
  description = "value of db-instance-name"
}
variable "db-instance-deletion-protection" {
  description = "value of db-instance-deletion prtection"
}
variable "db-instance-availability" {
  description = "value of db-instance-availability"
}

variable "db-instance-region" {
  description = "value of db-instance--region"
}
variable "db-instance-database-version" {
  description = "value of db-instance-database-version"
}
variable "db-instance-disk-type" {
  description = "value of db-instance-disk-type"
}
variable "db-instance-disk-size" {
  description = "value of db-instance-disk-size"
}
variable "db-instance-ipv4-enabled" {
  description = "value of db-instance-ipv4-enabled"
}
variable "google-sql-database-name" {
  description = "value of google-sql-database-name"
}
variable "google-sql-database-user" {
  description = "value of google-sql-database-user"
}

variable "global_address" {
  description = "value of global_address"
}

variable "global_address_type" {
  description = "value of global_address_type"
}

variable "global_address_purpose" {
  description = "value of global_address_purpose"
}

variable "global_address_length" {
  description = "value  of global_address_length"
  
}

variable "instance_tier" {
  description = "value of instance_tier"
}
variable "instance_edition" {
  description = "value of instance_edition"  
}

variable "instance_enabled" {
  description = "value"
}

variable "instance_log_enabled" {
  description = "value"
}

variable "sa_acc_id" {
  description = "value"
}

variable "sa_display_name" {
  description = "value"
}
variable "dns_name" {
  description = "value"
}
variable "a_record" {
  description = "value"
}
variable "a_record_ttl" {
  description = "value"
}
variable "dns_zone" {
  description = "value"
}

variable "topic_name" {
  description = "value"
}

variable "msg_duration" {
  description = "value"
}

variable "pubsub_sa_account_id" {
  description = "value"
}

variable "pubsub_sa_name" {
  description = "value"
}
variable "pubsub_sa_binding_role" {
  description = "value"
}
variable "pubsub_sub_sa_account_id" {
  description = "value"
}

variable "pubsub_sub_sa_display_name" {
  description = "value"
}
variable "verify_email_subscription_name" {
  description = "value"
}

variable "cloud_function_connector_name" {
  description = "value"
}
variable "cloud_function_connector_cidr" {
  description = "value"
}

variable "cloud_function_connector_throughput" {
 description = "value" 
}

variable "cloudfunction_sa_aid" {
  description = "value"
  
}
variable "cloudfunction_sa_dn" {
  description = "value"
}

variable "datatype" {
  description = "value"
}

variable "datasource" {
  description = "value"
}

variable "dataop" {
  description = "value"
}

variable "bucket_obj_name" {
  description = "value"
}

variable "obj_content_type" {
  description = "value"
}

variable "gcf_name" {
  description = "value"
}

variable "gcf_runtime" {
  description = "value"
}

variable "gcf_ep" {
  description = "value"
}

variable "trig_event_type" {
  description = "value"
}

variable "trig_retry_policy" {
  description = "value"
}

variable "sc_memory" {
  description = "value"
}

variable "sc_instance_count" {
  description = "value"
}
variable "sc_timeout_seconds" {
  description = "value"
}

variable "mg_domain" {
  description = "value"
}

variable "mg_api" {
  description = "value"
}

variable "pass" {
  default = "DefaultPassword123!"
}

variable "instance_template_sa_aid" {
  description = "value"
}
variable "instance_template_sa_dn" {
  description = "value"
}
variable "webapp_health_check_sa_aid" {
  description = "value"
}
variable "webapp_health_check_sa_dn" {
  description = "value" 
}
variable "template_name" {
  description = "value"
}
variable "template_dn" {
  description = "value"
}
variable "template_tags" {
  description = "value"
}
variable "template_boot" {
  description = "value"
}
variable "template_lifecycle" {
  description = "value" 
}
variable "health_check_name" {
  description = "value"
}
variable "health_checkinterval" {
  description = "value"
}
variable "health_checktimeout" {
  description = "value"
}
variable "health_check_portname" {
  description = "value"
}
variable "health_check_request_path" {
  description = "value"
}
variable "autoscaler_sa_aid" {
  description = "value"
}
variable "autoscaler_sa_dn" {
  description = "value"
}
variable "autoscaler_name" {
  description = "value"
}
variable "autoscaler_min" {
  description = "value"
}
variable "autoscaler_max" {
  description = "value"
}
variable "autoscaler_cpu" {
  description = "value"
}
variable "igm_name" {
  description = "value"
}
variable "igm_base_name" {
 description = "value" 
}
variable "igm_target_size" {
  description = "value"
}
variable "igm_port_name" {
  description = "value"
}
variable "distribution_policy_zones" {
  description = "value"
}
variable "igm_delay" {
  description = "value"
}
variable "ssl_name" {
  description = "value"
}
variable "ssl_domain" {
  description = "value" 
}
variable "global_forwarding_name" {
  description = "value"
}
variable "global_forwarding_port_range" {
  description = "value"
}
variable "global_forwarding_scheme" {
  description = "value"
}
variable "global_forwarding_ip_protocol" {
  description = "value"
}
variable "https_proxy_name" {
  description = "value"
}
variable "url_map_name" {
  description = "value"
}
variable "lb_backend_name" {
  description = "value"
}
variable "lb_backend_enable_cdn" {
  description = "value"
}
variable "lb_backend_port_name" {
  description = "value"
}
variable "lb_backend_protocol" {
  description = "value"
}
variable "lb_backend_balancing_mode" {
  description = "value"
}
variable "lb_backend_capacity_scaler" {
  description = "value"
}
variable "keyring_name" {
  description = "value"
}
variable "vmkey_name" {
 description = "value" 
}
variable "sqlkey_name" {
  description = "value"
}
variable "storekey_name" {
  description = "value"
}
variable "purpose" {
  description = "value"
}
variable "key_rotation_period" {
  description = "value"
}
variable "kms_role" {
  description = "value"
}
variable "sqlapis" {
  description = "value"
}