resource "random_password" "nsxt" {
  length           = 14
  special          = true
  number           = true
  override_special = "%@#"
  min_special      = 1
  min_numeric      = 1
  min_upper        = 1
}

resource "random_password" "vcenter" {
  length           = 14
  special          = true
  number           = true
  override_special = "%@#"
  min_special      = 1
  min_numeric      = 1
  min_upper        = 1
}


resource "azurerm_vmware_private_cloud" "privatecloud" {
  name                = var.sddc_name
  resource_group_name = var.rg_name
  location            = var.rg_location
  sku_name            = var.sddc_sku
  tags                = var.tags

  management_cluster {
    size = var.management_cluster_size
  }

  network_subnet_cidr         = var.avs_network_cidr
  internet_connection_enabled = false
  nsxt_password               = random_password.nsxt.result
  vcenter_password            = random_password.vcenter.result

  #timeouts {
  #  create = "10h"
  #}

  lifecycle {
    ignore_changes = [
      nsxt_password,
      vcenter_password
    ]
  }
}

resource "azurerm_vmware_express_route_authorization" "expressrouteauthkey" {
  name             = var.expressroute_authorization_key_name
  private_cloud_id = azurerm_vmware_private_cloud.privatecloud.id
}

resource "azurerm_virtual_network_gateway_connection" "avs" {
  name                = var.express_route_connection_name
  location            = var.rg_location
  resource_group_name = var.rg_name
  enable_bgp          = true

  type                       = "ExpressRoute"
  virtual_network_gateway_id = var.express_route_gateway_id
  express_route_circuit_id   = azurerm_vmware_private_cloud.privatecloud.circuit[0].express_route_id
  authorization_key          = azurerm_vmware_express_route_authorization.expressrouteauthkey.express_route_authorization_key
}
