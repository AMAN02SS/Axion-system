# ==============================================================================
# Axion System - 3-Tier Infrastructure (Root Module)
# ==============================================================================

# Central Resource Group for all Axion System resources
resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags     = var.tags
}

# ==============================================================================
# Child Module: Network (VNet, 3 Subnets, NSGs, and Security Rules)
# ==============================================================================
module "network" {
  source = "./modules/network"

  resource_group_name        = azurerm_resource_group.rg.name
  location                   = azurerm_resource_group.rg.location
  project_name               = var.project_name
  environment                = var.environment
  vnet_address_space         = var.vnet_address_space
  frontend_subnet_cidr       = var.frontend_subnet_cidr
  backend_subnet_cidr        = var.backend_subnet_cidr
  database_subnet_cidr       = var.database_subnet_cidr
  frontend_allowed_ssh_cidrs = var.frontend_allowed_ssh_cidrs
  backend_app_port           = var.backend_app_port
  tags                       = var.tags
}

# ==============================================================================
# Child Module: Database (Azure PostgreSQL Flexible Server PaaS)
# ==============================================================================
module "database" {
  source = "./modules/database"

  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  project_name        = var.project_name
  environment         = var.environment
  vnet_id             = module.network.vnet_id
  delegated_subnet_id = module.network.database_subnet_id
  postgres_version    = var.postgres_version
  sku_name            = var.postgres_sku_name
  storage_mb          = var.postgres_storage_mb
  admin_username      = var.postgres_admin_username
  admin_password      = var.postgres_admin_password
  database_name       = var.database_name
  tags                = var.tags
}

# ==============================================================================
# Child Module: Compute (Frontend VM with Public IP + Backend VM in Private Subnet)
# ==============================================================================
module "compute" {
  source = "./modules/compute"

  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  project_name         = var.project_name
  environment          = var.environment
  frontend_subnet_id   = module.network.frontend_subnet_id
  backend_subnet_id    = module.network.backend_subnet_id
  frontend_subnet_cidr = module.network.frontend_subnet_cidr
  backend_subnet_cidr  = module.network.backend_subnet_cidr
  vm_size              = var.vm_size
  admin_username       = var.admin_username
  ssh_public_key       = var.ssh_public_key
  backend_app_port     = var.backend_app_port
  db_host              = module.database.server_fqdn
  db_name              = module.database.database_name
  tags                 = var.tags
}

# ==============================================================================
# Local SSH Private Key File (Auto-generated if no key supplied)
# ==============================================================================
resource "local_sensitive_file" "ssh_private_key" {
  count           = var.save_ssh_key_locally && var.ssh_public_key == "" ? 1 : 0
  content         = module.compute.ssh_private_key_pem
  filename        = "${path.module}/${var.project_name}_${var.environment}_key.pem"
  file_permission = "0600"
}
