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