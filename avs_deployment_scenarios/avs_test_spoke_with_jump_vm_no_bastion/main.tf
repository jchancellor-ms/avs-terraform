locals {
  #jumpbox and bastion resource names  
  jumpbox_rg_name                    = "${var.prefix}-Jumpbox-${random_string.namestring.result}"
  jumpbox_spoke_vnet_name            = "${var.prefix}-AVS-vnet-jumpbox-${random_string.namestring.result}"
  jumpbox_spoke_vnet_connection_name = "${var.prefix}-AVS-vnet-connection-jumpbox-${random_string.namestring.result}"
  jumpbox_nic_name                   = "${var.prefix}-AVS-Jumpbox-Nic-${random_string.namestring.result}"
  jumpbox_name                       = "${var.prefix}-js-${random_string.namestring.result}"
  keyvault_name                      = "${var.prefix}-AVS-jump-kv-${random_string.namestring.result}"
  subnets = [
    {
      name           = "JumpBoxSubnet"
      address_prefix = [var.jumpbox_subnet_prefix]
    }
  ]
}

#create a random string for uniqueness during redeployments using the same values
resource "random_string" "namestring" {
  length  = 4
  special = false
  upper   = false
  lower   = true
}

#create spoke vnet
#deploy a new resource group for the jumpbox and bastion components
resource "azurerm_resource_group" "greenfield_jumpbox" {
  name     = local.jumpbox_rg_name
  location = var.region
}

module "spoke_vnet_for_jump" {
  source = "../../modules/avs_vnet_variable_subnets"

  rg_name            = azurerm_resource_group.greenfield_jumpbox.name
  rg_location        = azurerm_resource_group.greenfield_jumpbox.location
  vnet_name          = local.jumpbox_spoke_vnet_name
  vnet_address_space = var.jumpbox_spoke_vnet_address_space
  subnets            = local.subnets
  tags               = var.tags
}

#if vwan - create vwan vnet connection
data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}


#deploy the jumpbox host
module "avs_jumpbox" {
  source = "../../modules/avs_jumpbox"

  jumpbox_nic_name  = local.jumpbox_nic_name
  jumpbox_name      = local.jumpbox_name
  jumpbox_sku       = var.jumpbox_sku
  rg_name           = azurerm_resource_group.greenfield_jumpbox.name
  rg_location       = azurerm_resource_group.greenfield_jumpbox.location
  jumpbox_subnet_id = module.spoke_vnet_for_jump.subnet_ids["JumpBoxSubnet"].id
  admin_username    = var.admin_username
  key_vault_id      = var.keyvault_id
  tags              = var.tags

}

#get the hub vnet information.  Assumes hub is in the same subscription as the test spoke 
#TODO: Update this module to allow for the hub components to exist in a different subscription
data "azurerm_virtual_network" "hub_vnet" {
  name                = var.hub_vnet_name
  resource_group_name = var.hub_rg_name
}

#if not vwan - create vnet peer
resource "azurerm_virtual_network_peering" "hub_owned_peer" {
  name                      = "${local.jumpbox_spoke_vnet_name}-link"
  resource_group_name       = var.hub_rg_name
  virtual_network_name      = var.hub_vnet_name
  remote_virtual_network_id = module.spoke_vnet_for_jump.vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "spoke_owned_peer" {
  name                      = "${var.hub_vnet_name}-link"
  resource_group_name       = azurerm_resource_group.greenfield_jumpbox.name
  virtual_network_name      = module.spoke_vnet_for_jump.vnet_name
  remote_virtual_network_id = data.azurerm_virtual_network.hub_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = true
}
#TODO: If firewall add UDR
resource "azurerm_route_table" "spoke_udr" {
  name                          = "${local.jumpbox_spoke_vnet_name}-udr"
  location                      = azurerm_resource_group.greenfield_jumpbox.location
  resource_group_name           = azurerm_resource_group.greenfield_jumpbox.name
  disable_bgp_route_propagation = true
}

resource "azurerm_subnet_route_table_association" "firewall_subnet_rt" {
  subnet_id      = module.spoke_vnet_for_jump.subnet_ids["JumpBoxSubnet"].id
  route_table_id = azurerm_route_table.spoke_udr.id

  depends_on = [
    azurerm_route.firewall_internet_route
  ]
}

resource "azurerm_route" "firewall_internet_route" {
  name                   = "Internet"
  resource_group_name    = azurerm_resource_group.greenfield_jumpbox.name
  route_table_name       = azurerm_route_table.spoke_udr.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = var.firewall_ip
}
