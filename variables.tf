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
variable "source_ranges" {
  description = "Source IP ranges for the firewall rule"
  default     = "0.0.0.0/0"
}

variable "default_route_name" {
  description = "Name of the default route"
  default     = "default-route"
}

variable "routing_mode" {
  description = "Regional routing mode for the VPC"
  default     = "REGIONAL"
}

variable "webapp_port" {
  description = "Allowed port for the webapp"
  default     = "3000"
}

variable "restrict_port" {
  description = "Blocked port for the webapp"
  default     = "22"
}
variable "protocol" {
  description = "protocol"
  default     = "tcp"
}

variable "machine_type" {
  description = "The machine type for the Google Compute Engine instance"
  default     = "e2-medium"
}

variable "instance_name" {
  description = "The name of the Google Compute Engine instance"
  default     = "instance-1"
}

variable "tags" {
  description = "The tags for the Google Compute Engine instance"
  default     = ["http-server"]
}

variable "zone" {
  description = "The zone for the Google Compute Engine instance"
  default     = "us-east1-b"
}

variable "boot_disk_image" {
  description = "The image for the boot disk"
  default     = "projects/devproj-414701/global/images/custom-app-image"
}

variable "boot_disk_size" {
  description = "The size of the boot disk"
  default     = 100
}

variable "boot_disk_type" {
  description = "The type of the boot disk"
  default     = "pd-balanced"
}

