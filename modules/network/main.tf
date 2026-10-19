# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.project_name}-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = var.vnet_address_space
  tags                = var.tags
}

# Tier 1: Frontend Subnet
resource "azurerm_subnet" "frontend" {
  name                 = "snet-${var.project_name}-frontend"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.frontend_subnet_cidr]
}

# Tier 2: Backend Subnet
resource "azurerm_subnet" "backend" {
  name                 = "snet-${var.project_name}-backend"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.backend_subnet_cidr]
}

# Tier 3: Database Subnet (Delegated to PostgreSQL Flexible Server)
resource "azurerm_subnet" "database" {
  name                 = "snet-${var.project_name}-database"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.database_subnet_cidr]

  delegation {
    name = "psql-flexible-server-delegation"

    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

# ==============================================================================
# Network Security Groups (NSGs)
# ==============================================================================

# Frontend NSG: Allows public HTTP, HTTPS, and SSH traffic from designated sources
resource "azurerm_network_security_group" "frontend_nsg" {
  name                = "nsg-${var.project_name}-frontend"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "Allow-HTTP-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-HTTPS-Inbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH-Inbound"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.frontend_allowed_ssh_cidrs
    destination_address_prefix = "*"
  }
}

# Backend NSG: Only permits traffic from the Frontend Subnet (App Port & SSH)
# Explicitly denies direct inbound access from the Internet.
resource "azurerm_network_security_group" "backend_nsg" {
  name                = "nsg-${var.project_name}-backend"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "Allow-Frontend-To-Backend-App"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = tostring(var.backend_app_port)
    source_address_prefix      = var.frontend_subnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-Frontend-SSH-To-Backend"
    priority                   = 210
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.frontend_subnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-Direct-Internet-Inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

# Database NSG: Only permits PostgreSQL port 5432 from the Backend Subnet
resource "azurerm_network_security_group" "database_nsg" {
  name                = "nsg-${var.project_name}-database"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  security_rule {
    name                       = "Allow-Backend-To-PostgreSQL"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5432"
    source_address_prefix      = var.backend_subnet_cidr
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Deny-Direct-Internet-Inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

# ==============================================================================
# NSG to Subnet Associations
# ==============================================================================

resource "azurerm_subnet_network_security_group_association" "frontend" {
  subnet_id                 = azurerm_subnet.frontend.id
  network_security_group_id = azurerm_network_security_group.frontend_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "backend" {
  subnet_id                 = azurerm_subnet.backend.id
  network_security_group_id = azurerm_network_security_group.backend_nsg.id
}

resource "azurerm_subnet_network_security_group_association" "database" {
  subnet_id                 = azurerm_subnet.database.id
  network_security_group_id = azurerm_network_security_group.database_nsg.id
}
