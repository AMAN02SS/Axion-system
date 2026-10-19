variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for the virtual machines"
  type        = string
}

variable "project_name" {
  description = "Name of the project used in resource naming"
  type        = string
  default     = "axion"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"
}

variable "frontend_subnet_id" {
  description = "Subnet ID where the Frontend VM will be deployed"
  type        = string
}

variable "backend_subnet_id" {
  description = "Subnet ID where the Backend VM will be deployed"
  type        = string
}

variable "frontend_subnet_cidr" {
  description = "CIDR block of the Frontend subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "backend_subnet_cidr" {
  description = "CIDR block of the Backend subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "vm_size" {
  description = "Azure VM size for both Frontend and Backend VMs"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Administrator username for Linux VMs"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "Existing SSH public key. If left blank, a new key pair will be generated automatically."
  type        = string
  default     = ""
}

variable "backend_app_port" {
  description = "TCP port where the Backend service listens"
  type        = number
  default     = 8080
}

variable "db_host" {
  description = "FQDN of the PostgreSQL server for backend configuration"
  type        = string
  default     = ""
}

variable "db_name" {
  description = "Name of the PostgreSQL database"
  type        = string
  default     = "axion_db"
}

variable "tags" {
  description = "A mapping of tags to assign to compute resources"
  type        = map(string)
  default     = {}
}
