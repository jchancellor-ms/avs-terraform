locals {
  #jumpbox and bastion resource names  
  jumpbox_rg_name                    = "${var.prefix}-Jumpbox-${random_string.namestring.result}"
  jumpbox_spoke_vnet_name            = "${var.prefix}-AVS-vnet-jumpbox-${random_string.namestring.result}"
  jumpbox_spoke_vnet_connection_name = "${var.prefix}-AVS-vnet-connection-jumpbox-${random_string.namestring.result}"
  jumpbox_nic_name                   = "${var.prefix}-AVS-Jumpbox-Nic-${random_string.namestring.result}"
  jumpbox_name                       = "${var.prefix}-js-${random_string.namestring.result}"
  bastion_pip_name                   = "${var.prefix}-AVS-bastion-pip-${random_string.namestring.result}"
  bastion_name                       = "${var.prefix}-AVS-bastion-${random_string.namestring.result}"
  keyvault_name                      = "${var.prefix}-AVS-jump-kv-${random_string.namestring.result}"
  #list of RFC1918 top level summaries for use in VWAN routing
  private_range_prefixes = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
}

#create a random string for uniqueness during redeployments using the same values
resource "random_string" "namestring" {
  length  = 4
  special = false
  upper   = false
  lower   = true
}

##NOTE: The modules below this line are for initial testing and can be removed after the implementation if desired 
#Deploy firewall rules allowing outbound http, https, ntp, and dns
module "outbound_internet_test_firewall_rules" {
  source = "../../modules/avs_azure_firewall_internet_outbound_rules"

  firewall_policy_id = var.firewall_policy_id
  #avs_ip_ranges       = [var.avs_network_cidr, var.jumpbox_spoke_vnet_address_space[0]]
  private_range_prefixes = local.private_range_prefixes
  has_firewall_policy    = true
}

#deploy a new resource group for the jumpbox and bastion components
resource "azurerm_resource_group" "greenfield_jumpbox" {
  name     = local.jumpbox_rg_name
  location = var.region
}

#Deploy a vnet and virtual hub connection for the bastion and jumpbox
module "spoke_vnet_for_jump_and_bastion" {
  source                                 = "../../modules/avs_vwan_vnet_spoke"
  rg_name                                = azurerm_resource_group.greenfield_jumpbox.name
  rg_location                            = azurerm_resource_group.greenfield_jumpbox.location
  vwan_spoke_vnet_name                   = local.jumpbox_spoke_vnet_name
  vwan_spoke_vnet_address_space          = var.jumpbox_spoke_vnet_address_space
  virtual_hub_spoke_vnet_connection_name = local.jumpbox_spoke_vnet_connection_name
  virtual_hub_id                         = var.vwan_hub_id
  tags                                   = var.tags
  vwan_spoke_subnets = [
    {
      name           = "JumpboxSubnet",
      address_prefix = var.jumpbox_subnet_prefix
    },
    {
      name           = "AzureBastionSubnet",
      address_prefix = var.bastion_subnet_prefix
    }
  ]
}

#deploy the bastion host
module "avs_bastion" {
  source = "../../modules/avs_bastion_simple"

  bastion_pip_name  = local.bastion_pip_name
  bastion_name      = local.bastion_name
  rg_name           = azurerm_resource_group.greenfield_jumpbox.name
  rg_location       = azurerm_resource_group.greenfield_jumpbox.location
  bastion_subnet_id = module.spoke_vnet_for_jump_and_bastion.subnet_ids["AzureBastionSubnet"].id
  tags              = var.tags
}

#deploy the jumpbox
#deploy the key vault for the jump host
data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}

module "avs_keyvault_with_access_policy" {
  source = "../../modules/avs_key_vault"

  #values to create the keyvault
  rg_name            = azurerm_resource_group.greenfield_jumpbox.name
  rg_location        = azurerm_resource_group.greenfield_jumpbox.location
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
  rg_name           = azurerm_resource_group.greenfield_jumpbox.name
  rg_location       = azurerm_resource_group.greenfield_jumpbox.location
  jumpbox_subnet_id = module.spoke_vnet_for_jump_and_bastion.subnet_ids["JumpboxSubnet"].id
  admin_username    = var.admin_username
  key_vault_id      = module.avs_keyvault_with_access_policy.keyvault_id
  tags              = var.tags

  depends_on = [
    module.avs_keyvault_with_access_policy
  ]
}