resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "random_password" "db_password" {
  count            = var.admin_password == "" ? 1 : 0
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
  min_upper        = 2
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
}

locals {
  resolved_admin_password = var.admin_password != "" ? var.admin_password : random_password.db_password[0].result
}

# Private DNS Zone required for PostgreSQL Flexible Server VNet Integration
resource "azurerm_private_dns_zone" "pg_dns_zone" {
  name                = "${var.project_name}-${var.environment}-${random_string.suffix.result}.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

# Link Private DNS Zone to the system VNet
resource "azurerm_private_dns_zone_virtual_network_link" "pg_dns_link" {
  name                  = "vnetlink-${var.project_name}-${var.environment}"
  private_dns_zone_name = azurerm_private_dns_zone.pg_dns_zone.name
  virtual_network_id    = var.vnet_id
  resource_group_name   = var.resource_group_name
  tags                  = var.tags
}

# Azure Database for PostgreSQL Flexible Server (PaaS)
resource "azurerm_postgresql_flexible_server" "postgres" {
  name                   = "psql-${var.project_name}-${var.environment}-${random_string.suffix.result}"
  resource_group_name    = var.resource_group_name
  location               = var.location
  version                = var.postgres_version
  delegated_subnet_id    = var.delegated_subnet_id
  private_dns_zone_id    = azurerm_private_dns_zone.pg_dns_zone.id
  administrator_login    = var.admin_username
  administrator_password = local.resolved_admin_password
  sku_name               = var.sku_name
  storage_mb             = var.storage_mb
  backup_retention_days  = 7
  tags                   = var.tags

  # Ensure Private DNS Zone VNet Link is active before server creation
  depends_on = [azurerm_private_dns_zone_virtual_network_link.pg_dns_link]
}

# Default Database Creation
resource "azurerm_postgresql_flexible_server_database" "db" {
  name      = var.database_name
  server_id = azurerm_postgresql_flexible_server.postgres.id
  collation = "en_US.utf8"
  charset   = "utf8"
}
