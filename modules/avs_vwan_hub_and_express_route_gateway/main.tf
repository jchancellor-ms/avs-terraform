#create a virtual hub
resource "azurerm_virtual_hub" "vwan_hub" {
  name                = var.vwan_hub_name
  resource_group_name = var.rg_name
  location            = var.rg_location
  virtual_wan_id      = var.vwan_id
  address_prefix      = var.vwan_hub_address_prefix
  tags                = var.tags
}

resource "azurerm_express_route_gateway" "vwan_express_route_gateway" {
  name                = var.express_route_gateway_name
  resource_group_name = var.rg_name
  location            = var.rg_location
  virtual_hub_id      = azurerm_virtual_hub.vwan_hub.id
  scale_units         = var.express_route_scale_units

  tags = var.tags
}