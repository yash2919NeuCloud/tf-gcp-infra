variable "credentials_file" {
  description = "Path to the service account JSON key file"
}

variable "project_id" {
  description = "Google Cloud Project ID"
  default     = "cloud-neu-proj"
}

variable "region" {
  description = "Google Cloud region"
  default     = "us-east1"
}

variable "vpc_name" {
  description = "Name of the VPC"
  default     = "my-vpc"
}

variable "webapp_subnet_name" {
  description = "Name of the webapp subnet"
  default     = "webapp"
}

variable "db_subnet_name" {
  description = "Name of the db subnet"
  default     = "db"
}

variable "webapp_subnet_cidr" {
  description = "CIDR range for webapp subnet"
  default     = "10.0.1.0/24"
}

variable "db_subnet_cidr" {
  description = "CIDR range for db subnet"
  default     = "10.0.2.0/24"
}

variable "network_auto_create_subnets" {
  description = "Auto-create subnets for the VPC"
  default     = false
}

variable "next_hop_gateway" {
  description = "Next hop gateway for the default route"
  default     = "default-internet-gateway"
}

variable "default_route_dest_range" {
  description = "Destination IP range for the default route"
  default     = "0.0.0.0/0"
}

variable "default_route_name" {
  description = "Name of the default route"
  default     = "default-route"
}

