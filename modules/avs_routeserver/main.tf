resource "azurerm_virtual_hub" "virtual_hub" {
  name                = var.virtual_hub_name
  resource_group_name = var.rg_name
  location            = var.rg_location
  sku                 = "Standard"
}

resource "azurerm_public_ip" "routeserver_pip" {
  name                = var.virtual_hub_pip_name
  location            = var.rg_location
  resource_group_name = var.rg_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_virtual_hub_ip" "routeserver" {
  name                         = var.route_server_name
  virtual_hub_id               = azurerm_virtual_hub.virtual_hub.id
  private_ip_allocation_method = "Dynamic"
  public_ip_address_id         = azurerm_public_ip.routeserver_pip.id
  subnet_id                    = var.route_server_subnet_id
}