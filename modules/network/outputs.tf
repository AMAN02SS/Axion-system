output "vnet_id" {
  description = "The ID of the Virtual Network"
  value       = azurerm_virtual_network.vnet.id
}

output "vnet_name" {
  description = "The name of the Virtual Network"
  value       = azurerm_virtual_network.vnet.name
}

output "frontend_subnet_id" {
  description = "The Subnet ID for the Frontend tier"
  value       = azurerm_subnet.frontend.id
}

output "backend_subnet_id" {
  description = "The Subnet ID for the Backend tier"
  value       = azurerm_subnet.backend.id
}

output "database_subnet_id" {
  description = "The delegated Subnet ID for the PostgreSQL Database tier"
  value       = azurerm_subnet.database.id
}

output "frontend_subnet_cidr" {
  description = "CIDR block of the Frontend subnet"
  value       = var.frontend_subnet_cidr
}

output "backend_subnet_cidr" {
  description = "CIDR block of the Backend subnet"
  value       = var.backend_subnet_cidr
}

output "database_subnet_cidr" {
  description = "CIDR block of the Database subnet"
  value       = var.database_subnet_cidr
}
