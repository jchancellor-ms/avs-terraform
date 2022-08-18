# Create local variable derived from an input prefix or modify for customer naming
locals {
  #update naming convention with target naming convention if different
  #resource group names
  network_rg_name = "${var.prefix}-Network-${random_string.namestring.result}"

  #VWAN hub and gateway names  
  vwan_name                           = (var.vwan_already_exists ? var.vwan_name : "${var.prefix}-AVS-vwan-${random_string.namestring.result}")
  vwan_hub_name                       = "${var.prefix}-AVS-vwan-hub-${random_string.namestring.result}"
  vwan_firewall_policy_name           = "${var.prefix}-AVS-vwan-firewall-policy-${random_string.namestring.result}"
  vwan_firewall_name                  = "${var.prefix}-AVS-vwan-firewall-${random_string.namestring.result}"
  vwan_log_analytics_name             = "${var.prefix}-AVS-vwan-firewall-log-analytics-${random_string.namestring.result}"
  express_route_gateway_name          = "${var.prefix}-AVS-express-route-gw-${random_string.namestring.result}"
  vpn_gateway_name                    = "${var.prefix}-AVS-vpn-gw-${random_string.namestring.result}"
  all_branch_traffic_through_firewall = false

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
module "avs_vwan_hub_with_express_route_gateway" {
  source = "../../modules/avs_vwan_hub_and_express_route_gateway"

  rg_name                             = azurerm_resource_group.greenfield_network.name
  rg_location                         = azurerm_resource_group.greenfield_network.location
  vwan_id                             = module.avs_vwan.vwan_id
  vwan_hub_name                       = local.vwan_hub_name
  vwan_hub_address_prefix             = var.vwan_hub_address_prefix
  express_route_gateway_name          = local.express_route_gateway_name
  express_route_scale_units           = var.express_route_scale_units
  azure_firewall_id                   = module.avs_vwan_azure_firewall_w_policy_and_log_analytics.firewall_id
  all_branch_traffic_through_firewall = local.all_branch_traffic_through_firewall
  tags                                = var.tags
  private_range_prefixes              = local.private_range_prefixes
}

module "avs_vwan_azure_firewall_w_policy_and_log_analytics" {
  source = "../../modules/avs_vwan_azure_firewall_w_policy_and_log_analytics"

  rg_name                   = azurerm_resource_group.greenfield_network.name
  rg_location               = azurerm_resource_group.greenfield_network.location
  firewall_sku_tier         = var.firewall_sku_tier
  firewall_name             = local.vwan_firewall_name
  log_analytics_name        = local.vwan_log_analytics_name
  vwan_firewall_policy_name = local.vwan_firewall_policy_name
  virtual_hub_id            = module.avs_vwan_hub_with_express_route_gateway.vwan_hub_id
  public_ip_count           = var.hub_firewall_public_ip_count
  tags                      = var.tags
}

module "avs_test_secure_vwan_spoke_jump_bastion" {
  source = "../../avs_deployment_scenarios/avs_test_secure_vwan_spoke_jump_bastion"

  prefix                           = var.prefix
  region                           = var.region
  jumpbox_spoke_vnet_address_space = var.jumpbox_spoke_vnet_address_space
  bastion_subnet_prefix            = var.bastion_subnet_prefix
  jumpbox_subnet_prefix            = var.jumpbox_subnet_prefix
  jumpbox_sku                      = var.jumpbox_sku
  admin_username                   = var.jumpbox_admin_username
  tags                             = var.tags
  firewall_policy_id               = module.avs_vwan_azure_firewall_w_policy_and_log_analytics.firewall_policy_id
  vwan_hub_id                      = module.avs_vwan_hub_with_express_route_gateway.vwan_hub_id
}