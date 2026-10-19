output "server_id" {
  description = "The ID of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.postgres.id
}

output "server_name" {
  description = "The resource name of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.postgres.name
}

output "server_fqdn" {
  description = "Fully Qualified Domain Name (FQDN) of the PostgreSQL Flexible Server"
  value       = azurerm_postgresql_flexible_server.postgres.fqdn
}

output "database_name" {
  description = "The name of the provisioned PostgreSQL database"
  value       = azurerm_postgresql_flexible_server_database.db.name
}

output "admin_username" {
  description = "Administrator username for PostgreSQL"
  value       = var.admin_username
}

output "admin_password" {
  description = "Administrator password for PostgreSQL"
  value       = local.resolved_admin_password
  sensitive   = true
}

output "private_dns_zone_id" {
  description = "ID of the Private DNS Zone used by PostgreSQL"
  value       = azurerm_private_dns_zone.pg_dns_zone.id
}
