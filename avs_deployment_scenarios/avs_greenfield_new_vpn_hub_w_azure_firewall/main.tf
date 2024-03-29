# Create local variable derived from an input prefix or modify for customer naming
locals {
  #update naming convention with target naming convention if different
  private_cloud_rg_name               = "${var.prefix}-PrivateCloud-${random_string.namestring.result}"
  network_rg_name                     = "${var.prefix}-Network-${random_string.namestring.result}"
  vnet_name                           = "${var.prefix}-VirtualNetwork-${random_string.namestring.result}"
  sddc_name                           = "${var.prefix}-SDDC-${random_string.namestring.result}"
  expressroute_authorization_key_name = "${var.prefix}-AVS-ExpressrouteAuthKey-${random_string.namestring.result}"
  express_route_connection_name       = "${var.prefix}-AVS-ExpressrouteConnection-${random_string.namestring.result}"
  expressroute_pip_name               = "${var.prefix}-AVS-expressroute-gw-pip-${random_string.namestring.result}"
  expressroute_gateway_name           = "${var.prefix}-AVS-expressroute-gw-${random_string.namestring.result}"
  vpn_pip_name_1                      = "${var.prefix}-AVS-vpn-gw-pip-1-${random_string.namestring.result}"
  vpn_pip_name_2                      = "${var.prefix}-AVS-vpn-gw-pip-2-${random_string.namestring.result}"
  vpn_gateway_name                    = "${var.prefix}-AVS-vpn-gw-${random_string.namestring.result}"
  firewall_pip_name                   = "${var.prefix}-AVS-firewall-pip-${random_string.namestring.result}"
  firewall_name                       = "${var.prefix}-AVS-firewall-${random_string.namestring.result}"
  log_analytics_name                  = "${var.prefix}-AVS-log-analytics-${random_string.namestring.result}"
  virtual_hub_name                    = "${var.prefix}-AVS-virtual-hub-${random_string.namestring.result}"
  virtual_hub_pip_name                = "${var.prefix}-AVS-virtual-hub-pip-${random_string.namestring.result}"
  route_server_name                   = "${var.prefix}-AVS-virtual-route-server-${random_string.namestring.result}"
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

#Create a virtual network with gateway, bastion, and jumpbox subnets
module "avs_virtual_network" {
  source = "../../modules/avs_vnet_w_gateway_routeserver_and_azure_firewall"

  vnet_name                  = local.vnet_name
  vnet_address_space         = var.vnet_address_space
  rg_name                    = azurerm_resource_group.greenfield_network.name
  rg_location                = azurerm_resource_group.greenfield_network.location
  gateway_subnet_prefix      = var.gateway_subnet_prefix
  route_server_subnet_prefix = var.route_server_subnet_prefix
  firewall_subnet_prefix     = var.firewall_subnet_prefix
  tags                       = var.tags
}

#deploy the expressroute gateway in the gateway subnet 
module "avs_expressroute_gateway" {
  source = "../../modules/avs_expressroute_gateway"

  expressroute_pip_name           = local.expressroute_pip_name
  expressroute_gateway_name       = local.expressroute_gateway_name
  expressroute_gateway_sku        = var.expressroute_gateway_sku
  rg_name                         = azurerm_resource_group.greenfield_network.name
  rg_location                     = azurerm_resource_group.greenfield_network.location
  gateway_subnet_id               = module.avs_virtual_network.gateway_subnet_id
  express_route_connection_name   = local.express_route_connection_name
  express_route_id                = module.avs_private_cloud.sddc_express_route_id
  express_route_authorization_key = module.avs_private_cloud.sddc_express_route_authorization_key

  depends_on = [
    module.avs_vpn_gateway
  ]
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

#deploy a VPNGateway
module "avs_vpn_gateway" {
  source = "../../modules/avs_vpn_gateway"

  vpn_pip_name_1    = local.vpn_pip_name_1
  vpn_pip_name_2    = local.vpn_pip_name_2
  vpn_gateway_name  = local.vpn_gateway_name
  vpn_gateway_sku   = var.vpn_gateway_sku
  asn               = var.asn
  rg_name           = azurerm_resource_group.greenfield_network.name
  rg_location       = azurerm_resource_group.greenfield_network.location
  gateway_subnet_id = module.avs_virtual_network.gateway_subnet_id
}

#deploy a routeserver
module "avs_routeserver" {
  source = "../../modules/avs_routeserver"

  rg_name                = azurerm_resource_group.greenfield_network.name
  rg_location            = azurerm_resource_group.greenfield_network.location
  virtual_hub_name       = local.virtual_hub_name
  virtual_hub_pip_name   = local.virtual_hub_pip_name
  route_server_name      = local.route_server_name
  route_server_subnet_id = module.avs_virtual_network.route_server_subnet_id
}

#deploy azure firewall in the hub
module "avs_azure_firewall" {
  source = "../../modules/avs_azure_firewall_w_log_analytics"

  rg_name            = azurerm_resource_group.greenfield_network.name
  rg_location        = azurerm_resource_group.greenfield_network.location
  firewall_sku_tier  = var.firewall_sku_tier
  tags               = var.tags
  firewall_pip_name  = local.firewall_pip_name
  firewall_name      = local.firewall_name
  firewall_subnet_id = module.avs_virtual_network.firewall_subnet_id
  log_analytics_name = local.log_analytics_name
}

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