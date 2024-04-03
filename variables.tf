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
  default     = "my-vpc-3"
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

variable "global_address_name" {
  description = "Name of the global address"
  default     = "private-ip-address"
}

variable "global_address_purpose" {
  description = "Purpose of the global address"
  default     = "VPC_PEERING"
}

variable "global_address_type" {
  description = "Type of the global address"
  default     = "INTERNAL"
}

variable "global_address_prefix_length" {
  description = "Prefix length of the global address"
  default     = 16
}

variable "service_name" {
  description = "The name of the service"
  default     = "servicenetworking.googleapis.com"
}
variable "sql_instance_name" {
  description = "The name of the SQL instance."
  type        = string
  default     = "sqlinstance"
}

variable "disk_size_gb" {
  description = "The size of the disk in GB for the SQL instance."
  type        = number
  default     = 100
}

variable "sql_machine_type" {
  description = "The machine type for the SQL instance."
  type        = string
  default     = "db-n1-standard-1"
}
variable "availability_type" {
  description = "The availability type for the SQL instance."
  type        = string
  default     = "REGIONAL"
}
variable "disk_type" {
  description = "The disk type for the SQL instance."
  type        = string
  default     = "pd-ssd"
}
variable "database_name" {
  description = "The name of the SQL database."
  type        = string
  default     = "webapp"
}
variable "database_user_name" {
  description = "The name of the SQL user."
  type        = string
  default     = "webapp"
}
variable "database_user_password_length" {
  description = "The length of the SQL user password."
  type        = number
  default     = 16
}
variable "database_version" {
  description = "The version of the MySQL database."
  type        = string
  default     = "MYSQL_8_0"
}
variable "dns_record" {
  description = "dns_record"
  type        = string
  default     = "yashnahata.me."
}

variable "managed_zone" {
  description = "managed_zone"
  type        = string
  default     = "yash-nahata"
}

variable "ttl" {
  description = "ttl"
  type        = number
  default     = 300
}

variable "key" {
  type = string
}

variable "entry_point" {
  type    = string
  default = "helloPubSub"
}

variable "max_instance_count" {
  description = "max_instance_count"
  type        = number
  default     = 1
}

variable "timeout_seconds" {
  type    = string
  default = "60"
}

variable "available_memory" {
  type    = string
  default = "256M"
}
variable "runtime" {
  type    = string
  default = "nodejs20"
}

variable "min_instances" {
  description = "min_instances"
  type        = number
  default     = 2
}

variable "max_instances" {
  description = "max_instances"
  type        = number
  default     = 3
}


variable "machine_type_vpc_connector" {
  type    = string
  default = "f1-micro"

}

variable "message_retention_duration" {
  type    = string
  default = "604800s"
}

variable "src" {
  type    = string
  default = "C:/Users/yashn/Downloads/cloud_func.zip"
}

variable "ack_deadline_seconds" {
  type    = number
  default = 10

}

variable "ip_cidr_range" {
  type    = string
  default = "10.8.0.0/28"

}
variable "google_pubsub_topic_name" {
  type    = string
  default = "verify_email"

}

variable "google_storage_bucket_name" {
  type    = string
  default = "yash-bucket-cloud-291"

}

variable "location" {
  type    = string
  default = "US"

}

variable "retry_policy" {

  type    = string
  default = "RETRY_POLICY_RETRY"

}
variable "event_type" {
  type    = string
  default = "google.cloud.pubsub.topic.v1.messagePublished"
}


variable "vpc_connector_egress_settings" {
  type    = string
  default = "PRIVATE_RANGES_ONLY"
}
