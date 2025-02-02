variable "region" {
  description = "AWS region"
  default     = "us-east-1"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "your_ip" {
  description = "Your IP address for SSH access"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.medium"
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  default     = 30
}

variable "db_volume_size" {
  description = "Size of database volume in GB"
  default     = 20
}

variable "my_ip" {
  description = "Your IP address for SSH access (in CIDR notation, e.g., 1.2.3.4/32)"
  type        = string
} 