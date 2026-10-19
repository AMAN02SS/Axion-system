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
ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDCDESbLXa+RbFjQR4RTzunSO2nzJ2WIfyFZc0Rzy55La5QNamkJhPbGf+J9zn+/kyWCtZ19N1il1zXEeOSCVD3K38nTILy4bWRIGaY/UWfOGVkhe5HvjAMtaew2UoAqvU9vhafGYxhcaYLzoFU3uykUGplQKB0696TjGZ8u2kINNh2oUxP99Exml7e96tb0MBWUu+GKisPmwvyvcx7ESBkgVdIOF3GxIm3YCpwH57MDrOKJhJbVmfy7P4gzC+sj7xPI4jO1xokijAGMKu69EI5MDcpxQ9437vHYKiOfJQsajb+EXbkh4MW7TiM59+uGlDAlc+QEMzxQvM9l00XO0bnv0JKAbPAbaeD6fzY/lYjlIvGYuGG+XSSoTD/1sc84tmrqBGvJaWiVOWnqeR0Yqnx1fy5DG+CREa+OzldMRyBCxMfdjwbh/df2dzuJgmr25Yy0vJAUMr3B4CYVN0c83htZgJeawsR19oIQzrcyv8+h2wjecE+SEyT55wfbYAceUQLAw3z37msCibbjlrlWI29x+JnLEBOT0wiCWh82ufbm4MhJdObhrMMm639AdWaRvoQzYbdwBxKsCpx21tsgwluckqDvqh4lM5++vPOJIqanz5H86d+//xnMS+xRDJG+AW4VfGIPSqKwpo+noCOOJPneckbChqeeS9eBLbrHmz1oQ== aman_02@DESKTOP-MD1MDN0
"

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
