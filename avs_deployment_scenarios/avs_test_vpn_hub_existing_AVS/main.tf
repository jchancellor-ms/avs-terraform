locals {


  network_rg_name = "${var.prefix}-Network-${random_string.namestring.result}"
  vnet_name       = "${var.prefix}-VirtualNetwork-${random_string.namestring.result}"


  expressroute_authorization_key_name = "${var.prefix}-AVS-ExpressrouteAuthKey-${random_string.namestring.result}"
  express_route_connection_name       = "${var.prefix}-AVS-ExpressrouteConnection-${random_string.namestring.result}"

  expressroute_pip_name     = "${var.prefix}-AVS-expressroute-gw-pip-${random_string.namestring.result}"
  expressroute_gateway_name = "${var.prefix}-AVS-expressroute-gw-${random_string.namestring.result}"

  vpn_pip_name_1   = "${var.prefix}-AVS-vpn-gw-pip-1-${random_string.namestring.result}"
  vpn_pip_name_2   = "${var.prefix}-AVS-vpn-gw-pip-2-${random_string.namestring.result}"
  vpn_gateway_name = "${var.prefix}-AVS-vpn-gw-${random_string.namestring.result}"

  firewall_pip_name  = "${var.prefix}-AVS-firewall-pip-${random_string.namestring.result}"
  firewall_name      = "${var.prefix}-AVS-firewall-${random_string.namestring.result}"
  log_analytics_name = "${var.prefix}-AVS-log-analytics-${random_string.namestring.result}"

  virtual_hub_name     = "${var.prefix}-AVS-virtual-hub-${random_string.namestring.result}"
  virtual_hub_pip_name = "${var.prefix}-AVS-virtual-hub-pip-${random_string.namestring.result}"
  route_server_name    = "${var.prefix}-AVS-virtual-route-server-${random_string.namestring.result}"

}


#create a random string for uniqueness during redeployments using the same values
resource "random_string" "namestring" {
  length  = 4
  special = false
  upper   = false
  lower   = true
}

#Create the Network objects resource group
resource "azurerm_resource_group" "greenfield_network" {
  name     = local.network_rg_name
  location = var.region
}

#Create a virtual network with gateway, routeserver, and firewall nva subnets
module "avs_hub_virtual_network" {
  source = "../../modules/avs_vnet_variable_subnets"

  rg_name            = azurerm_resource_group.greenfield_network.name
  rg_location        = azurerm_resource_group.greenfield_network.location
  vnet_name          = local.vnet_name
  vnet_address_space = var.vnet_address_space
  subnets            = var.subnets
  tags               = var.tags
}

data "azurerm_vmware_private_cloud" "test-sddc" {
  name                = var.sddc_name
  resource_group_name = var.sddc_rg_name
}

resource "azurerm_vmware_express_route_authorization" "expressrouteauthkey" {
  name             = local.expressroute_authorization_key_name
  private_cloud_id = data.azurerm_vmware_private_cloud.test-sddc.id
  depends_on = [
    data.azurerm_vmware_private_cloud.test-sddc
  ]
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
  express_route_id                = data.azurerm_vmware_private_cloud.test-sddc.circuit[0].express_route_id
  express_route_authorization_key = azurerm_vmware_express_route_authorization.expressrouteauthkey.express_route_authorization_key
  depends_on = [
    module.avs_vpn_gateway,
    azurerm_vmware_express_route_authorization.expressrouteauthkey
  ]
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
  gateway_subnet_id = module.avs_hub_virtual_network.subnet_ids["GatewaySubnet"].id
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
