locals {
  #update naming convention with target naming convention if different
  test_on_prem_rg_name = "${var.prefix}-on-prem-rg-${random_string.namestring.result}"
  vnet_name            = "${var.prefix}-on-prem-virtualNetwork-${random_string.namestring.result}"

  csr_node0_name = "csr-node0-${random_string.namestring.result}"
  vpn_pip_name_1 = "${var.prefix}-on-prem-csr-pip-1-${random_string.namestring.result}"

  bastion_pip_name = "${var.prefix}-on-prem-bastion-pip-${random_string.namestring.result}"
  bastion_name     = "${var.prefix}-on-prem-bastion-${random_string.namestring.result}"

  keyvault_name = "${var.prefix}-op-kv-${random_string.namestring.result}"

  jumpbox_nic_name = "${var.prefix}-op-Jumpbox-Nic-${random_string.namestring.result}"
  jumpbox_name     = "${var.prefix}-jump"
  route_table_name = "${var.prefix}-jump-subnet-rt"
}

module "csr_vpn_appliance" {
  source = "../../modules/avs_nva_cisco_1000v_vpn_config_one_node"

  rg_name              = azurerm_resource_group.test_on_prem.name
  rg_location          = azurerm_resource_group.test_on_prem.location
  pre_shared_key       = var.pre_shared_key
  asn                  = var.asn
  csr_bgp_ip           = var.csr_bgp_ip
  csr_tunnel_cidr      = var.csr_tunnel_cidr
  csr_subnet_cidr      = module.on_prem_hub_virtual_network.subnet_ids[var.csr_subnet_name].address_prefixes[0]
  csr_vnet_cidr        = module.on_prem_hub_virtual_network.vnet_cidr
  remote_gw_pubip0     = var.remote_gw_pubip0
  remote_gw_pubip1     = var.remote_gw_pubip1
  remote_bgp_peer_ip_0 = var.remote_bgp_peer_ips[0]
  remote_bgp_peer_ip_1 = var.remote_bgp_peer_ips[1]
  node0_name           = local.csr_node0_name
  fw_facing_subnet_id  = module.on_prem_hub_virtual_network.subnet_ids[var.csr_subnet_name].id
  keyvault_id          = module.on_prem_keyvault_with_access_policy.keyvault_id
  vpn_pip_name_1       = local.vpn_pip_name_1

  depends_on = [
    module.on_prem_hub_virtual_network
  ]
}


#create a random string for uniqueness during redeployments using the same values
resource "random_string" "namestring" {
  length  = 4
  special = false
  upper   = false
  lower   = true
}

#Create the Network objects resource group
resource "azurerm_resource_group" "test_on_prem" {
  name     = local.test_on_prem_rg_name
  location = var.region
}

#Create a virtual network with gateway, routeserver, and firewall nva subnets
module "on_prem_hub_virtual_network" {
  source = "../../modules/avs_vnet_variable_subnets"

  rg_name            = azurerm_resource_group.test_on_prem.name
  rg_location        = azurerm_resource_group.test_on_prem.location
  vnet_name          = local.vnet_name
  vnet_address_space = var.vnet_address_space
  subnets            = var.subnets
  tags               = var.tags
}



#deploy the bastion host
module "avs_bastion" {
  source = "../../modules/avs_bastion_simple"

  bastion_pip_name  = local.bastion_pip_name
  bastion_name      = local.bastion_name
  rg_name           = azurerm_resource_group.test_on_prem.name
  rg_location       = azurerm_resource_group.test_on_prem.location
  bastion_subnet_id = module.on_prem_hub_virtual_network.subnet_ids["AzureBastionSubnet"].id
  tags              = var.tags
}

#deploy the key vault for the jump host

data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}

module "on_prem_keyvault_with_access_policy" {
  source = "../../modules/avs_key_vault"

  #values to create the keyvault
  rg_name            = azurerm_resource_group.test_on_prem.name
  rg_location        = azurerm_resource_group.test_on_prem.location
  keyvault_name      = local.keyvault_name
  azure_ad_tenant_id = data.azurerm_client_config.current.tenant_id
  #deployment_user_object_id = data.azurerm_client_config.current.object_id
  deployment_user_object_id = data.azuread_client_config.current.object_id #temp fix for az cli breaking change
  tags                      = var.tags
}

#deploy the jumpbox host
module "avs_jumpbox" {
  source = "../../modules/avs_jumpbox"

  jumpbox_nic_name  = local.jumpbox_nic_name
  jumpbox_name      = local.jumpbox_name
  jumpbox_sku       = var.jumpbox_sku
  rg_name           = azurerm_resource_group.test_on_prem.name
  rg_location       = azurerm_resource_group.test_on_prem.location
  jumpbox_subnet_id = module.on_prem_hub_virtual_network.subnet_ids["JumpBoxSubnet"].id
  admin_username    = var.admin_username
  key_vault_id      = module.on_prem_keyvault_with_access_policy.keyvault_id
  tags              = var.tags
}

resource "azurerm_route_table" "jump_private_static" {
  name                          = local.route_table_name
  location                      = azurerm_resource_group.test_on_prem.location
  resource_group_name           = azurerm_resource_group.test_on_prem.name
  disable_bgp_route_propagation = false

  tags = var.tags
}

resource "azurerm_route" "rfc_1918_10" {
  name                   = "rfc_1918_10"
  resource_group_name    = azurerm_resource_group.test_on_prem.name
  route_table_name       = azurerm_route_table.jump_private_static.name
  address_prefix         = "10.0.0.0/8"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.csr_vpn_appliance.private_ip_address
}

resource "azurerm_route" "rfc_1918_172" {
  name                   = "rfc_1918_172"
  resource_group_name    = azurerm_resource_group.test_on_prem.name
  route_table_name       = azurerm_route_table.jump_private_static.name
  address_prefix         = "172.16.0.0/12"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.csr_vpn_appliance.private_ip_address
}

resource "azurerm_route" "rfc_1918_192" {
  name                   = "rfc_1918_192"
  resource_group_name    = azurerm_resource_group.test_on_prem.name
  route_table_name       = azurerm_route_table.jump_private_static.name
  address_prefix         = "192.168.0.0/16"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = module.csr_vpn_appliance.private_ip_address
}

resource "azurerm_subnet_route_table_association" "jump_private_addresses" {
  subnet_id      = module.on_prem_hub_virtual_network.subnet_ids["JumpBoxSubnet"].id
  route_table_id = azurerm_route_table.jump_private_static.id
}