# ==============================================================================
# Axion System - Example Variables Configuration
# Copy this file to `terraform.tfvars` and edit as needed.
# ==============================================================================

# General
project_name = "axion"
environment  = "dev"
location     = "centralindia"

# Network CIDRs (All inside one single VNet)
vnet_address_space   = ["10.0.0.0/16"]
frontend_subnet_cidr = "10.0.1.0/24"
backend_subnet_cidr  = "10.0.2.0/24"
database_subnet_cidr = "10.0.3.0/24"

# Security: Restrict SSH to your current public IP for maximum security (e.g., ["203.0.113.50/32"])
frontend_allowed_ssh_cidrs = ["0.0.0.0/0"]

# Compute Settings
vm_size              = "Standard_B2s_v2"
admin_username       = "azureuser"
save_ssh_key_locally = true
backend_app_port     = 8080

# If you have an existing SSH public key, paste it here. If left empty (""), Terraform generates one.
ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII5csJgfh++AdJa1fVULN3qbwZFq9yMTX1VrSqZxDgFU github-actions-deploy"

# Database Settings (Azure PostgreSQL Flexible Server PaaS)
postgres_version        = "15"
postgres_sku_name       = "B_Standard_B1ms"
postgres_storage_mb     = 32768
postgres_admin_username = "psqladmin"
database_name           = "axion_db"

# If left empty (""), a secure 20-character password is automatically generated.
postgres_admin_password = "YourCustomPassword123!"

# Tags
tags = {
  Project      = "Axion"
  Environment  = "dev"
  Architecture = "3-Tier"
  ManagedBy    = "Terraform"
}
