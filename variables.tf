# ==============================================================================
# General Project Variables
# ==============================================================================

variable "project_name" {
  description = "The name of the project, used for resource prefixing"
  type        = string
  default     = "axion"

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region where resources will be deployed"
  type        = string
  default     = "eastus"
}

# ==============================================================================
# Network Configuration
# ==============================================================================

variable "vnet_address_space" {
  description = "Address space for the single unified Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "frontend_subnet_cidr" {
  description = "CIDR range for Tier 1: Frontend Subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "backend_subnet_cidr" {
  description = "CIDR range for Tier 2: Backend Subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "database_subnet_cidr" {
  description = "CIDR range for Tier 3: PostgreSQL Delegated Subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "frontend_allowed_ssh_cidrs" {
  description = "List of public IP CIDRs allowed to SSH into the Frontend VM (e.g., your public IP /32)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# ==============================================================================
# Compute Configuration (Frontend & Backend VMs)
# ==============================================================================

variable "vm_size" {
  description = "Size of the Virtual Machines (both Frontend and Backend)"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "SSH administrator username for the VMs"
  type        = string
  default     = "azureuser"
}

variable "ssh_public_key" {
  description = "Optional existing SSH public key. If omitted, a secure 4096-bit RSA key is generated automatically."
  type        = string
  default     = ""
}

variable "save_ssh_key_locally" {
  description = "Whether to save the auto-generated private key to a local .pem file on disk"
  type        = bool
  default     = true
}

variable "backend_app_port" {
  description = "Internal TCP port used by the Backend service"
  type        = number
  default     = 8080
}

# ==============================================================================
# Database Configuration (PostgreSQL Flexible Server)
# ==============================================================================

variable "postgres_version" {
  description = "PostgreSQL major version"
  type        = string
  default     = "15"
}

variable "postgres_sku_name" {
  description = "SKU for PostgreSQL Flexible Server"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgres_storage_mb" {
  description = "Storage allocated for PostgreSQL in MB"
  type        = number
  default     = 32768
}

variable "postgres_admin_username" {
  description = "Administrator login username for PostgreSQL"
  type        = string
  default     = "psqladmin"
}

variable "postgres_admin_password" {
  description = "Administrator password for PostgreSQL. If omitted, a secure 20-character password is automatically generated."
  type        = string
  default     = ""
  sensitive   = true
}

variable "database_name" {
  description = "Initial PostgreSQL database to create"
  type        = string
  default     = "axion_db"
}

# ==============================================================================
# Resource Tags
# ==============================================================================

variable "tags" {
  description = "Common tags applied to all Azure resources"
  type        = map(string)
  default = {
    Project      = "Axion"
    Architecture = "3-Tier"
    ManagedBy    = "Terraform"
  }
}
