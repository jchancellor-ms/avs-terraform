# Create local variable derived from an input prefix or modify for customer naming
locals {
  #update naming convention with target naming convention if different
  private_cloud_rg_name = "${var.prefix}-PrivateCloud-${random_string.namestring.result}"
  network_rg_name       = "${var.prefix}-Network-${random_string.namestring.result}"

  #vnet_name = "${var.prefix}-VirtualNetwork-${random_string.namestring.result}"
  sddc_name                           = "${var.prefix}-SDDC-${random_string.namestring.result}"
  expressroute_authorization_key_name = "${var.prefix}-AVS-ExpressrouteAuthKey-${random_string.namestring.result}"
  express_route_connection_name       = "${var.prefix}-AVS-ExpressrouteConnection-${random_string.namestring.result}"

  #expressroute_pip_name     = "${var.prefix}-AVS-expressroute-gw-pip-${random_string.namestring.result}"
  express_route_gateway_name = "${var.prefix}-AVS-express-route-gw-${random_string.namestring.result}"

  #vpn_pip_name_1   = "${var.prefix}-AVS-vpn-gw-pip-1-${random_string.namestring.result}"
  #vpn_pip_name_2   = "${var.prefix}-AVS-vpn-gw-pip-2-${random_string.namestring.result}"
  vpn_gateway_name = "${var.prefix}-AVS-vpn-gw-${random_string.namestring.result}"

  #firewall_pip_name  = "${var.prefix}-AVS-firewall-pip-${random_string.namestring.result}"
  #firewall_name      = "${var.prefix}-AVS-firewall-${random_string.namestring.result}"
  #log_analytics_name = "${var.prefix}-AVS-log-analytics-${random_string.namestring.result}"

  vwan_name = (var.vwan_already_exists ? var.vwan_name : "${var.prefix}-AVS-vwan-${random_string.namestring.result}")

  vwan_hub_name = "${var.prefix}-AVS-vwab-hub-${random_string.namestring.result}"
  #virtual_hub_pip_name = "${var.prefix}-AVS-virtual-hub-pip-${random_string.namestring.result}"
  #route_server_name    = "${var.prefix}-AVS-virtual-route-server-${random_string.namestring.result}"

  #action_group_name         = "${var.prefix}-AVS-action-group-${random_string.namestring.result}"
  #action_group_shortname    = "avs-sddc-sh"
  #service_health_alert_name = "${var.prefix}-AVS-service-health-alert-${random_string.namestring.result}"
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

resource "azurerm_resource_group" "greenfield_network" {
  name     = local.network_rg_name
  location = var.region
}

module "avs_vwan" {
  source = "../../modules/avs_vwan"

  rg_name             = azurerm_resource_group.greenfield_network.name
  rg_location         = azurerm_resource_group.greenfield_network.location
  vwan_name           = local.vwan_name
  vwan_already_exists = var.vwan_already_exists
  tags                = var.tags
}

#deploy the VWAN hub with the VPN and ExR gateways
module "avs_vwan_hub_with_vpn_and_express_route_gateways" {
  source = "../../modules/avs_vwan_hub_express_route_gateway_and_vpn_gateway"

  rg_name                    = azurerm_resource_group.greenfield_network.name
  rg_location                = azurerm_resource_group.greenfield_network.location
  vwan_id                    = module.avs_vwan.vwan_id
  vwan_hub_name              = local.vwan_hub_name
  vwan_hub_address_prefix    = var.vwan_hub_address_prefix
  express_route_gateway_name = local.express_route_gateway_name
  express_route_scale_units  = var.express_route_scale_units
  vpn_gateway_name           = local.vpn_gateway_name
  vpn_scale_units            = var.vpn_scale_units
  tags                       = var.tags
}

#deploy the private cloud
module "avs_private_cloud" {
  source = "../../modules/avs_private_cloud_single_management_cluster_no_internet_conn"

  sddc_name                           = local.sddc_name
  sddc_sku                            = var.sddc_sku
  management_cluster_size             = var.management_cluster_size
  rg_name                             = azurerm_resource_group.greenfield_privatecloud.name
  rg_location                         = azurerm_resource_group.greenfield_privatecloud.location
  avs_network_cidr                    = var.avs_network_cidr
  expressroute_authorization_key_name = local.expressroute_authorization_key_name
  express_route_gateway_id            = module.avs_vwan_hub_with_vpn_and_express_route_gateways.express_route_gateway_id
  express_route_connection_name       = local.express_route_connection_name
  tags                                = var.tags
}