# ==============================================================================
# Axion System - Outputs
# ==============================================================================

output "resource_group_name" {
  description = "The Resource Group containing all Axion System resources"
  value       = azurerm_resource_group.rg.name
}

# ------------------------------------------------------------------------------
# Tier 1: Frontend VM Outputs
# ------------------------------------------------------------------------------
output "frontend_public_ip" {
  description = "Public IP address of the Frontend VM (Accessible to users via browser/curl)"
  value       = module.compute.frontend_public_ip
}

output "frontend_web_url" {
  description = "Web URL to access the Frontend UI in your browser"
  value       = "http://${module.compute.frontend_public_ip}"
}

output "frontend_ssh_command" {
  description = "Command to SSH directly into the Frontend VM"
  value       = "ssh -i ${var.project_name}_${var.environment}_key.pem ${var.admin_username}@${module.compute.frontend_public_ip}"
}

# ------------------------------------------------------------------------------
# Tier 2: Backend VM Outputs
# ------------------------------------------------------------------------------
output "backend_private_ip" {
  description = "Private IP address of the Backend VM (Internal to VNet, isolated from public internet)"
  value       = module.compute.backend_private_ip
}

output "backend_ssh_command_via_jumpbox" {
  description = "Command to SSH into the Backend VM using Frontend VM as a bastion/jumpbox"
  value       = "ssh -i ${var.project_name}_${var.environment}_key.pem -J ${var.admin_username}@${module.compute.frontend_public_ip} ${var.admin_username}@${module.compute.backend_private_ip}"
}

# ------------------------------------------------------------------------------
# Tier 3: PostgreSQL Database Outputs
# ------------------------------------------------------------------------------
output "database_fqdn" {
  description = "Fully Qualified Domain Name (FQDN) for Azure PostgreSQL Flexible Server"
  value       = module.database.server_fqdn
}

output "database_name" {
  description = "Name of the default PostgreSQL database"
  value       = module.database.database_name
}

output "database_admin_username" {
  description = "PostgreSQL administrator login name"
  value       = module.database.admin_username
}

output "database_admin_password" {
  description = "PostgreSQL administrator password (sensitive)"
  value       = module.database.admin_password
  sensitive   = true
}

output "ssh_private_key_file" {
  description = "Path to the generated SSH private key file on your local machine"
  value       = var.save_ssh_key_locally && var.ssh_public_key == "" ? "${path.module}/${var.project_name}_${var.environment}_key.pem" : "User-provided key used"
}

output "architecture_summary" {
  description = "Quick summary of traffic routing and isolation in the 3-Tier Axion System"
  value       = <<-EOT
    ================================================================================
    Axion System 3-Tier Architecture Flow:
    1. Client/User -> Frontend VM:
       - Endpoint: http://${module.compute.frontend_public_ip}
       - Subnet: snet-axion-frontend (${module.network.frontend_subnet_cidr})
       - Port 80 (HTTP) & 443 (HTTPS) open to Internet.
    2. Frontend VM -> Backend VM:
       - Target: http://${module.compute.backend_private_ip}:${var.backend_app_port}
       - Subnet: snet-axion-backend (${module.network.backend_subnet_cidr})
       - Direct internet traffic is BLOCKED by NSG. Only Frontend subnet permitted.
    3. Backend VM -> PostgreSQL Flexible Server:
       - Target: ${module.database.server_fqdn}:5432
       - Subnet: snet-axion-database (${module.network.database_subnet_cidr}) [Delegated]
       - Only Backend subnet is permitted on port 5432.
    ================================================================================
  EOT
}
