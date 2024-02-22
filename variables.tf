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