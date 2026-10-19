variable "resource_group_name" {
  description = "The name of the resource group in which network resources are created"
  type        = string
}

variable "location" {
  description = "The Azure region where network resources are provisioned"
  type        = string
}

variable "project_name" {
  description = "Name of the project used in naming conventions"
  type        = string
  default     = "axion"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vnet_address_space" {
  description = "Address space for the Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "frontend_subnet_cidr" {
  description = "CIDR block for the Frontend subnet (Tier 1)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "backend_subnet_cidr" {
  description = "CIDR block for the Backend subnet (Tier 2)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "database_subnet_cidr" {
  description = "CIDR block for the PostgreSQL Database delegated subnet (Tier 3)"
  type        = string
  default     = "10.0.3.0/24"
}

variable "frontend_allowed_ssh_cidrs" {
  description = "List of CIDR blocks permitted to SSH into the Frontend VM"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "backend_app_port" {
  description = "TCP port on which the Backend service listens for Frontend requests"
  type        = number
  default     = 8080
}

variable "tags" {
  description = "A mapping of tags to assign to network resources"
  type        = map(string)
  default     = {}
}
