# This module creates the virtual network and required subnets
resource "azurerm_virtual_network" "network" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = var.rg_location
  resource_group_name = var.rg_name
  tags                = var.tags
}

resource "azurerm_subnet" "gateway_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = var.gateway_subnet_prefix
}

resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = var.bastion_subnet_prefix
}

resource "azurerm_subnet" "route_server_subnet" {
  name                 = "RouteServerSubnet"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = var.route_server_subnet_prefix
}

resource "azurerm_subnet" "jumpbox_subnet" {
  name                 = "JumpboxSubnet"
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.network.name
  address_prefixes     = var.jumpbox_subnet_prefix
}
