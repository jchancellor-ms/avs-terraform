locals {
  #update naming convention with target naming convention if different
  test_on_prem_rg_name = "${var.prefix}-on-prem-rg-${random_string.namestring.result}"
  vnet_name            = "${var.prefix}-on-prem-virtualNetwork-${random_string.namestring.result}"

  vpn_pip_name_1   = "${var.prefix}-on-prem-vpn-gw-pip-1-${random_string.namestring.result}"
  vpn_gateway_name = "${var.prefix}-on-prem-vpn-gw-${random_string.namestring.result}"

  bastion_pip_name = "${var.prefix}-on-prem-bastion-pip-${random_string.namestring.result}"
  bastion_name     = "${var.prefix}-on-prem-bastion-${random_string.namestring.result}"

  keyvault_name = "${var.prefix}-on-prem-keyvault-${random_string.namestring.result}"

  jumpbox_nic_name = "${var.prefix}-on-prem-Jumpbox-Nic-${random_string.namestring.result}"
  jumpbox_name     = "${var.prefix}-on-prem-Jumpbox-${random_string.namestring.result}"
}

resource "random_string" "namestring" {
  length  = 4
  special = false
  upper   = false
  lower   = true
}

#Create a resource group for the jumpbox and bastion
resource "azurerm_resource_group" "test_on_prem" {
  name     = local.test_on_prem_rg_name
  location = var.region
}

#create an on-prem virtual network with gateway, bastion, and jump
module "on_prem_virtual_network" {
  source = "../../modules/avs_vnet_w_gateway_bastion_and_jumpbox"

  vnet_name             = local.vnet_name
  vnet_address_space    = var.vnet_address_space
  rg_name               = azurerm_resource_group.test_on_prem.name
  rg_location           = azurerm_resource_group.test_on_prem.location
  gateway_subnet_prefix = var.gateway_subnet_prefix
  bastion_subnet_prefix = var.bastion_subnet_prefix
  jumpbox_subnet_prefix = var.jumpbox_subnet_prefix
  tags                  = var.tags
}

module "on_prem_vpn_gateway" {
  source = "../../modules/on_prem_vpn_gateway"

  vpn_pip_name_1    = local.vpn_pip_name_1
  vpn_gateway_name  = local.vpn_gateway_name
  vpn_gateway_sku   = var.vpn_gateway_sku
  rg_name           = azurerm_resource_group.test_on_prem.name
  rg_location       = azurerm_resource_group.test_on_prem.location
  gateway_subnet_id = module.on_prem_virtual_network.gateway_subnet_id
}

#deploy the bastion host
module "avs_bastion" {
  source = "../../modules/avs_bastion_simple"

  bastion_pip_name  = local.bastion_pip_name
  bastion_name      = local.bastion_name
  rg_name           = azurerm_resource_group.test_on_prem.name
  rg_location       = azurerm_resource_group.test_on_prem.location
  bastion_subnet_id = module.on_prem_virtual_network.bastion_subnet_id
  tags              = var.tags
}

#deploy the key vault for the jump host
data "azurerm_client_config" "current" {

}

module "on_prem_keyvault_with_access_policy" {
  source = "../../modules/avs_key_vault"

  #values to create the keyvault
  rg_name                   = azurerm_resource_group.test_on_prem.name
  rg_location               = azurerm_resource_group.test_on_prem.location
  keyvault_name             = local.keyvault_name
  azure_ad_tenant_id        = data.azurerm_client_config.current.tenant_id
  deployment_user_object_id = data.azurerm_client_config.current.object_id
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
  jumpbox_subnet_id = module.on_prem_virtual_network.jumpbox_subnet_id
  admin_username    = var.admin_username
  key_vault_id      = module.on_prem_keyvault_with_access_policy.keyvault_id
  tags              = var.tags
}