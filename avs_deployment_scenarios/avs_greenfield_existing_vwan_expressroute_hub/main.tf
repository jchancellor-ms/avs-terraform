locals {
  private_cloud_rg_name               = "${var.prefix}-PrivateCloud-${random_string.namestring.result}"
  sddc_name                           = "${var.prefix}-SDDC-${random_string.namestring.result}"
  expressroute_authorization_key_name = "${var.prefix}-AVS-ExpressrouteAuthKey-${random_string.namestring.result}"
  express_route_connection_name       = "${var.prefix}-AVS-ExpressrouteConnection-${random_string.namestring.result}"
  action_group_name                   = "${var.prefix}-AVS-action-group-${random_string.namestring.result}"
  action_group_shortname              = "avs-sddc-sh"
  service_health_alert_name           = "${var.prefix}-AVS-service-health-alert-${random_string.namestring.result}"
}

#create a random string for uniqueness during redeployments using the same values
resource "random_string" "namestring" {
  length  = 4
  special = false
  upper   = false
  lower   = true
}


#get the existing VWAN hub details
data "azurerm_virtual_hub" "existing" {
  name                = var.vwan_hub_name
  resource_group_name = var.vwan_hub_resource_group_name
}


#create a resource group for the private cloud
resource "azurerm_resource_group" "greenfield_privatecloud" {
  name     = local.private_cloud_rg_name
  location = var.region
}

#create the AVS private cloud
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

/*
data "azurerm_resource_group" "private_cloud" {
  name = var.sddc_rg_name
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
*/

resource "azurerm_express_route_connection" "avs_private_cloud_connection" {
  name                     = local.express_route_connection_name
  express_route_gateway_id = var.express_route_gateway_id
  #express_route_circuit_peering_id = module.avs_private_cloud.sddc_express_route_private_peering_id
  express_route_circuit_peering_id = data.azurerm_vmware_private_cloud.test-sddc.circuit[0].express_route_private_peering_id
  #authorization_key                = module.avs_private_cloud.sddc_express_route_authorization_key
  authorization_key        = azurerm_vmware_express_route_authorization.expressrouteauthkey.express_route_authorization_key
  enable_internet_security = var.is_secure_hub #publish a default route to the internet through Azure Firewall when true
}


module "avs_service_health" {
  source = "../../modules/avs_service_health"

  rg_name = azurerm_resource_group.greenfield_privatecloud.name
  #rg_name                       = data.azurerm_resource_group.private_cloud.name
  action_group_name             = local.action_group_name
  action_group_shortname        = local.action_group_shortname
  email_addresses               = var.email_addresses
  service_health_alert_name     = local.service_health_alert_name
  service_health_alert_scope_id = azurerm_resource_group.greenfield_privatecloud.id
  #service_health_alert_scope_id = data.azurerm_resource_group.private_cloud.id
  private_cloud_id = module.avs_private_cloud.sddc_id
  #private_cloud_id               = data.azurerm_vmware_private_cloud.test-sddc.id
}

