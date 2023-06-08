resource "random_password" "nsxt" {
  length           = 14
  special          = true
  numeric          = true
  override_special = "%@#"
  min_special      = 1
  min_numeric      = 1
  min_upper        = 1
}

resource "random_password" "vcenter" {
  length           = 14
  special          = true
  numeric          = true
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
  internet_connection_enabled = var.internet_enabled
  nsxt_password               = random_password.nsxt.result
  vcenter_password            = random_password.vcenter.result

  timeouts {
    create = "20h"
  }

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

#deploy the hcx addon if the hcx_enabled variable is set to true
module "hcx_addon" {
  count  = var.hcx_enabled ? 1 : 0
  source = "../avs_addon_hcx"

  private_cloud_name           = azurerm_vmware_private_cloud.privatecloud.name
  private_cloud_resource_group = var.rg_name
  hcx_key_names                = var.hcx_key_names

  depends_on = [
    azurerm_vmware_private_cloud.privatecloud
  ]
}