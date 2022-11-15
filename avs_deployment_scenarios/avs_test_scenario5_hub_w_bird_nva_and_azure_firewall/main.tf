terraform {
  required_providers {
    azapi = {
      source = "azure/azapi"
    }
  }
}

locals {
  hub_rg_name                         = "${var.prefix}-Network-${random_string.namestring.result}"
  vnet_name                           = "${var.prefix}-VirtualNetwork-${random_string.namestring.result}"
  nva_name                            = "${var.prefix}-nva-${random_string.namestring.result}"
  expressroute_authorization_key_name = "${var.prefix}-AVS-ExpressrouteAuthKey-${random_string.namestring.result}"
  express_route_connection_name       = "${var.prefix}-AVS-ExpressrouteConnection-${random_string.namestring.result}"
  expressroute_pip_name               = "${var.prefix}-AVS-expressroute-gw-pip-${random_string.namestring.result}"
  expressroute_gateway_name           = "${var.prefix}-AVS-expressroute-gw-${random_string.namestring.result}"
  globalreach_name                    = "${var.prefix}-globalreach-${random_string.namestring.result}"
  bastion_pip_name                    = "${var.prefix}-AVS-bastion-pip-${random_string.namestring.result}"
  bastion_name                        = "${var.prefix}-AVS-bastion-${random_string.namestring.result}"
  keyvault_name                       = "${var.prefix}-AVS-jump-kv-1-${random_string.namestring.result}"
  firewall_pip_name                   = "${var.prefix}-AVS-firewall-pip-${random_string.namestring.result}"
  firewall_name                       = "${var.prefix}-AVS-firewall-${random_string.namestring.result}"
  firewall_policy_name                = "${var.prefix}-AVS-firewall-policy-${random_string.namestring.result}"
  firewall_route_table_name           = "${var.prefix}-AVS-firewall-udr-${random_string.namestring.result}"
  log_analytics_name                  = "${var.prefix}-AVS-log-analytics-${random_string.namestring.result}"
  virtual_hub_name                    = "${var.prefix}-AVS-virtual-hub-${random_string.namestring.result}"
  virtual_hub_pip_name                = "${var.prefix}-AVS-virtual-hub-pip-${random_string.namestring.result}"
  route_server_name                   = "${var.prefix}-AVS-virtual-route-server-${random_string.namestring.result}"
  rs_subnet                           = [for subnet in var.subnets : subnet if subnet.name == "RouteServerSubnet"]
  nva_subnet                          = [for subnet in var.subnets : subnet if subnet.name == "NVASubnet"]

}

#create a random string for uniqueness during redeployments using the same values
resource "random_string" "namestring" {
  length  = 4
  special = false
  upper   = false
  lower   = true
}

#Create the hub resource group
resource "azurerm_resource_group" "hub_network_rg" {
  name     = local.hub_rg_name
  location = var.region
}

#create the vnet with bastion, azure firewall, NVA front, NVA back, Route server, gateway subnet
module "avs_hub_virtual_network" {
  source = "../../modules/avs_vnet_variable_subnets"

  rg_name            = azurerm_resource_group.hub_network_rg.name
  rg_location        = azurerm_resource_group.hub_network_rg.location
  vnet_name          = local.vnet_name
  vnet_address_space = var.vnet_address_space
  subnets            = var.subnets
  tags               = var.tags
}

#deploy Azure firewall
#deploy azure firewall in the hub
module "avs_azure_firewall" {
  source = "../../modules/avs_azure_firewall_w_log_analytics"

  rg_name              = azurerm_resource_group.hub_network_rg.name
  rg_location          = azurerm_resource_group.hub_network_rg.location
  firewall_sku_tier    = var.firewall_sku_tier
  tags                 = var.tags
  firewall_pip_name    = local.firewall_pip_name
  firewall_name        = local.firewall_name
  firewall_subnet_id   = module.avs_hub_virtual_network.subnet_ids["AzureFirewallSubnet"].id
  log_analytics_name   = local.log_analytics_name
  firewall_policy_name = local.firewall_policy_name
}


#deploy the quad0 NVA (try the bird config)
module "avs_test_quad_0_nva" {
  source = "../../modules/avs_test_quad_0_nva_frr"

  rg_name                    = azurerm_resource_group.hub_network_rg.name
  rg_location                = azurerm_resource_group.hub_network_rg.location
  nva_subnet_id              = module.avs_hub_virtual_network.subnet_ids["NVASubnet"].id
  nva_name                   = local.nva_name
  azfw_private_ip            = module.avs_azure_firewall.firewall_private_ip_address
  nva_asn                    = var.nva_asn
  route_server               = module.avs_routeserver.routeserver_details
  key_vault_id               = module.avs_keyvault_with_access_policy.keyvault_id
  virtual_hub_id             = module.avs_routeserver.virtual_hub_id
  route_server_subnet_prefix = local.rs_subnet[0].address_prefix[0]
  nva_subnet_prefix          = local.nva_subnet[0].address_prefix[0]
  #prefix_list     = var.nva_routing_prefixes
}

#create a keyvault for the NVA secrets
data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}

module "avs_keyvault_with_access_policy" {
  source = "../../modules/avs_key_vault"

  #values to create the keyvault
  rg_name                   = azurerm_resource_group.hub_network_rg.name
  rg_location               = azurerm_resource_group.hub_network_rg.location
  keyvault_name             = local.keyvault_name
  azure_ad_tenant_id        = data.azurerm_client_config.current.tenant_id
  deployment_user_object_id = data.azuread_client_config.current.object_id
  tags                      = var.tags
}

#deploy Azure Bastion
module "avs_bastion" {
  source = "../../modules/avs_bastion_simple"

  bastion_pip_name  = local.bastion_pip_name
  bastion_name      = local.bastion_name
  rg_name           = azurerm_resource_group.hub_network_rg.name
  rg_location       = azurerm_resource_group.hub_network_rg.location
  bastion_subnet_id = module.avs_hub_virtual_network.subnet_ids["AzureBastionSubnet"].id
  tags              = var.tags
}

#deploy route server and configure with NVA IP 
module "avs_routeserver" {
  source = "../../modules/avs_routeserver"

  rg_name                = azurerm_resource_group.hub_network_rg.name
  rg_location            = azurerm_resource_group.hub_network_rg.location
  virtual_hub_name       = local.virtual_hub_name
  virtual_hub_pip_name   = local.virtual_hub_pip_name
  route_server_name      = local.route_server_name
  route_server_subnet_id = module.avs_hub_virtual_network.subnet_ids["RouteServerSubnet"].id
}


#deploy expressRoute gateway 
##Get the existing private cloud
data "azurerm_vmware_private_cloud" "test-sddc" {
  name                = var.sddc_name
  resource_group_name = var.sddc_rg_name
}

##Generate a new authorization key
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
  rg_name                         = azurerm_resource_group.hub_network_rg.name
  rg_location                     = azurerm_resource_group.hub_network_rg.location
  gateway_subnet_id               = module.avs_hub_virtual_network.subnet_ids["GatewaySubnet"].id
  express_route_connection_name   = local.express_route_connection_name
  express_route_id                = data.azurerm_vmware_private_cloud.test-sddc.circuit[0].express_route_id
  express_route_authorization_key = azurerm_vmware_express_route_authorization.expressrouteauthkey.express_route_authorization_key
  #express_route_id = "dummyid"
  #express_route_authorization_key = "dummykey"

  depends_on = [
    azurerm_vmware_express_route_authorization.expressrouteauthkey
  ]

}

#create UDR for firewall subnet overriding the 0/0 route
resource "azurerm_route_table" "firewall_udr" {
  name                = "${local.firewall_name}-udr"
  location            = azurerm_resource_group.hub_network_rg.location
  resource_group_name = azurerm_resource_group.hub_network_rg.name
}

resource "azurerm_subnet_route_table_association" "firewall_subnet_rt" {
  subnet_id      = module.avs_hub_virtual_network.subnet_ids["AzureFirewallSubnet"].id
  route_table_id = azurerm_route_table.firewall_udr.id
}

resource "azurerm_route" "firewall_internet_route" {
  name                = "Internet"
  resource_group_name = azurerm_resource_group.hub_network_rg.name
  route_table_name    = azurerm_route_table.firewall_udr.name
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "Internet"
}


/*
#create globalreach connection
resource "azapi_resource" "globalreach" {
  type      = "Microsoft.AVS/privateClouds@2022-05-01"
  name      = local.globalreach_name
  parent_id = azurerm_resource_group.hub_network_rg.id
  location  = azurerm_resource_group.hub_network_rg.location

  body = jsonencode({
    properties = {
      peerExpressRouteCircuit = var.globalreach_circuit_id,
      authorizationKey        = var.globalreach_authkey
    }
  })
}
*/


