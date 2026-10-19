variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
}

variable "location" {
  description = "The Azure region for the PostgreSQL Flexible Server"
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

variable "vnet_id" {
  description = "The ID of the Virtual Network to link the Private DNS Zone"
  type        = string
}

variable "delegated_subnet_id" {
  description = "The Subnet ID delegated to Microsoft.DBforPostgreSQL/flexibleServers"
  type        = string
}

variable "postgres_version" {
  description = "PostgreSQL major version (e.g. 13, 14, 15, 16)"
  type        = string
  default     = "15"
}

variable "sku_name" {
  description = "The SKU name for PostgreSQL Flexible Server (e.g. B_Standard_B1ms, GP_Standard_D2s_v3)"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "storage_mb" {
  description = "Max storage allowed for PostgreSQL server in MB (min 32768)"
  type        = number
  default     = 32768
}

variable "admin_username" {
  description = "PostgreSQL administrator login name"
  type        = string
  default     = "psqladmin"
}

variable "admin_password" {
  description = "PostgreSQL administrator password. If empty, a secure password is automatically generated."
  type        = string
  default     = ""
  sensitive   = true
}

variable "database_name" {
  description = "Name of the default PostgreSQL database to create"
  type        = string
  default     = "axion_db"
}

variable "tags" {
  description = "A mapping of tags to assign to database resources"
  type        = map(string)
  default     = {}
}
