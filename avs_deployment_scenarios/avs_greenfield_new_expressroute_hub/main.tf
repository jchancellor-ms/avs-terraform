# Create local variable derived from an input prefix or modify for customer naming
locals {
  #update naming convention with target naming convention if different
  private_cloud_rg_name               = "${var.prefix}-PrivateCloud-${random_string.namestring.result}"
  network_rg_name                     = "${var.prefix}-Network-${random_string.namestring.result}"
  vnet_name                           = "${var.prefix}-VirtualNetwork-${random_string.namestring.result}"
  sddc_name                           = "${var.prefix}-AVS-SDDC-${random_string.namestring.result}"
  expressroute_authorization_key_name = "${var.prefix}-AVS-ExpressrouteAuthKey-${random_string.namestring.result}"
  express_route_connection_name       = "${var.prefix}-AVS-ExpressrouteConnection-${random_string.namestring.result}"
  expressroute_pip_name               = "${var.prefix}-AVS-expressroute-gw-pip-${random_string.namestring.result}"
  expressroute_gateway_name           = "${var.prefix}-AVS-expressroute-gw-${random_string.namestring.result}"
  service_health_alert_name           = "${var.prefix}-AVS-service-health-alert-${random_string.namestring.result}"
  action_group_name                   = "${var.prefix}-AVS-action-group-${random_string.namestring.result}"
  action_group_shortname              = "avs-sddc-sh"
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

#Create a virtual network with subnets for gateway and routeserver and any custom NVA subnets
module "avs_virtual_network" {
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
  gateway_subnet_id               = module.avs_virtual_network.subnet_ids["GatewaySubnet"].id
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


#deploy the default service health and azure monitor alerts
module "avs_service_health" {
  source = "../../modules/avs_service_health"

  rg_name                       = azurerm_resource_group.greenfield_privatecloud.name
  action_group_name             = local.action_group_name
  action_group_shortname        = local.action_group_shortname
  email_addresses               = var.email_addresses
  service_health_alert_name     = local.service_health_alert_name
  service_health_alert_scope_id = azurerm_resource_group.greenfield_privatecloud.id
  private_cloud_id              = module.avs_private_cloud.sddc_id
}

#deploy a test VM and bastion spoke for initial configuration and testing
module "avs_jumpbox_and_bastion" {
  source = "../../modules/avs_test_spoke_with_jump_vm"

  prefix                           = var.prefix
  region                           = var.region
  jumpbox_sku                      = var.jumpbox_sku
  admin_username                   = var.jumpbox_admin_username
  tags                             = var.tags
  hub_vnet_name                    = local.vnet_name
  hub_rg_name                      = azurerm_resource_group.greenfield_network.name
  jumpbox_spoke_vnet_address_space = var.jumpbox_spoke_vnet_address_space
  bastion_subnet_prefix            = var.bastion_subnet_prefix
  jumpbox_subnet_prefix            = var.jumpbox_subnet_prefix

  depends_on = [
    module.avs_virtual_network
  ]
}