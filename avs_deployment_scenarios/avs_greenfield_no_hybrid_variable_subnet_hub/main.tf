# Create local variable derived from an input prefix or modify for customer naming
locals {
  #update naming convention with target naming convention if different
  private_cloud_rg_name = "${var.prefix}-PrivateCloud-${random_string.namestring.result}"
  network_rg_name       = "${var.prefix}-Network-${random_string.namestring.result}"
  jumpbox_rg_name       = "${var.prefix}-Jumpbox-${random_string.namestring.result}"

  vnet_name = "${var.prefix}-VirtualNetwork-${random_string.namestring.result}"

  sddc_name                           = "${var.prefix}-SDDC-${random_string.namestring.result}"
  expressroute_authorization_key_name = "${var.prefix}-AVS-ExpressrouteAuthKey-${random_string.namestring.result}"
  express_route_connection_name       = "${var.prefix}-AVS-ExpressrouteConnection-${random_string.namestring.result}"

  expressroute_pip_name     = "${var.prefix}-AVS-expressroute-gw-pip-${random_string.namestring.result}"
  expressroute_gateway_name = "${var.prefix}-AVS-expressroute-gw-${random_string.namestring.result}"

  bastion_pip_name = "${var.prefix}-AVS-bastion-pip-${random_string.namestring.result}"
  bastion_name     = "${var.prefix}-bastion-${random_string.namestring.result}"

  virtual_hub_name     = "${var.prefix}-AVS-virtual-hub-${random_string.namestring.result}"
  virtual_hub_pip_name = "${var.prefix}-AVS-virtual-hub-pip-${random_string.namestring.result}"
  route_server_name    = "${var.prefix}-AVS-virtual-route-server-${random_string.namestring.result}"

  keyvault_name = "${var.prefix}-AVS-kv-${random_string.namestring.result}"

  jumpbox_nic_name = "${var.prefix}-AVS-Jumpbox-Nic-${random_string.namestring.result}"
  jumpbox_name     = "${var.prefix}-jmp"
}

#create a random string for uniqueness during redeployments using the same values
resource "random_string" "namestring" {
  length  = 4
  special = false
  upper   = false
  lower   = true
}

#Create the private cloud resource group
resource "azurerm_resource_group" "greenfield_privatecloud" {
  name     = local.private_cloud_rg_name
  location = var.region
}

#Create the Network objects resource group
resource "azurerm_resource_group" "greenfield_network" {
  name     = local.network_rg_name
  location = var.region
}

#Create a resource group for the jumpbox and bastion
resource "azurerm_resource_group" "greenfield_jumpbox" {
  name     = local.jumpbox_rg_name
  location = var.region
}

module "avs_hub_virtual_network" {
  source = "../../modules/avs_vnet_variable_subnets"

  rg_name            = azurerm_resource_group.greenfield_network.name
  rg_location        = azurerm_resource_group.greenfield_network.location
  vnet_name          = local.vnet_name
  vnet_address_space = var.vnet_address_space
  subnets            = var.subnets
  tags               = var.tags
}


#deploy the expressroute gateway in the gateway subnet 
module "avs_expressroute_gateway" {
  source = "../../modules/avs_expressroute_gateway"

  expressroute_pip_name           = local.expressroute_pip_name
  expressroute_gateway_name       = local.expressroute_gateway_name
  expressroute_gateway_sku        = var.expressroute_gateway_sku
  rg_name                         = azurerm_resource_group.greenfield_network.name
  rg_location                     = azurerm_resource_group.greenfield_network.location
  gateway_subnet_id               = module.avs_hub_virtual_network.subnet_ids["GatewaySubnet"].id
  express_route_connection_name   = local.express_route_connection_name
  express_route_id                = module.avs_private_cloud.sddc_express_route_id
  express_route_authorization_key = module.avs_private_cloud.sddc_express_route_authorization_key
}


#deploy a private cloud with a single management cluster and connect to the expressroute gateway
module "avs_private_cloud" {
  source = "../../modules/avs_private_cloud_single_management_cluster_no_internet_conn"

  sddc_name                           = local.sddc_name
  sddc_sku                            = var.sddc_sku
  management_cluster_size             = var.management_cluster_size
  rg_name                             = azurerm_resource_group.greenfield_privatecloud.name
  rg_location                         = azurerm_resource_group.greenfield_privatecloud.location
  avs_network_cidr                    = var.avs_network_cidr
  expressroute_authorization_key_name = local.expressroute_authorization_key_name
  tags                                = var.tags
}


#deploy the bastion host
module "avs_bastion" {
  source = "../../modules/avs_bastion_simple"

  bastion_pip_name  = local.bastion_pip_name
  bastion_name      = local.bastion_name
  rg_name           = azurerm_resource_group.greenfield_jumpbox.name
  rg_location       = azurerm_resource_group.greenfield_jumpbox.location
  bastion_subnet_id = module.avs_hub_virtual_network.subnet_ids["AzureBastionSubnet"].id
  tags              = var.tags
}

#deploy the key vault for the jump host
data "azurerm_client_config" "current" {

}

module "avs_keyvault_with_access_policy" {
  source = "../../modules/avs_key_vault"

  #values to create the keyvault
  rg_name                   = azurerm_resource_group.greenfield_jumpbox.name
  rg_location               = azurerm_resource_group.greenfield_jumpbox.location
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
  rg_name           = azurerm_resource_group.greenfield_jumpbox.name
  rg_location       = azurerm_resource_group.greenfield_jumpbox.location
  jumpbox_subnet_id = module.avs_hub_virtual_network.subnet_ids["JumpBoxSubnet"].id
  admin_username    = var.admin_username
  key_vault_id      = module.avs_keyvault_with_access_policy.keyvault_id
  tags              = var.tags
}

#deploy a routeserver
module "avs_routeserver" {
  source = "../../modules/avs_routeserver"

  rg_name                = azurerm_resource_group.greenfield_network.name
  rg_location            = azurerm_resource_group.greenfield_network.location
  virtual_hub_name       = local.virtual_hub_name
  virtual_hub_pip_name   = local.virtual_hub_pip_name
  route_server_name      = local.route_server_name
  route_server_subnet_id = module.avs_hub_virtual_network.subnet_ids["RouteServerSubnet"].id
}