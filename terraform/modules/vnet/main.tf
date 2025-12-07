# Azure Virtual Network Module
# This module creates a Virtual Network with public and private subnets for AKS

resource "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  address_space       = var.vnet_cidr
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = merge(var.tags, {
    Name        = var.vnet_name
    Environment = var.environment
  })
}

# Public Subnets
resource "azurerm_subnet" "public" {
  count                = length(var.public_subnets)
  name                 = "public-subnet-${count.index + 1}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.public_subnets[count.index]]
}

# Private Subnets
resource "azurerm_subnet" "private" {
  count                = length(var.private_subnets)
  name                 = "private-subnet-${count.index + 1}"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.private_subnets[count.index]]

  # Enable private endpoint network policies for AKS
  private_endpoint_network_policies = "Enabled"
}

# Network Security Group for Public Subnets
resource "azurerm_network_security_group" "public" {
  name                = "${var.vnet_name}-public-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Network Security Group for Private Subnets
resource "azurerm_network_security_group" "private" {
  name                = "${var.vnet_name}-private-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Associate NSG with Public Subnets
resource "azurerm_subnet_network_security_group_association" "public" {
  count                     = length(azurerm_subnet.public)
  subnet_id                 = azurerm_subnet.public[count.index].id
  network_security_group_id = azurerm_network_security_group.public.id
}

# Associate NSG with Private Subnets
resource "azurerm_subnet_network_security_group_association" "private" {
  count                     = length(azurerm_subnet.private)
  subnet_id                 = azurerm_subnet.private[count.index].id
  network_security_group_id = azurerm_network_security_group.private.id
}

# Route Table for Public Subnets
resource "azurerm_route_table" "public" {
  name                = "${var.vnet_name}-public-rt"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Route Table for Private Subnets
resource "azurerm_route_table" "private" {
  name                = "${var.vnet_name}-private-rt"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = var.tags
}

# Associate Route Tables with Subnets
resource "azurerm_subnet_route_table_association" "public" {
  count          = length(azurerm_subnet.public)
  subnet_id      = azurerm_subnet.public[count.index].id
  route_table_id = azurerm_route_table.public.id
}

resource "azurerm_subnet_route_table_association" "private" {
  count          = length(azurerm_subnet.private)
  subnet_id      = azurerm_subnet.private[count.index].id
  route_table_id = azurerm_route_table.private.id
}

