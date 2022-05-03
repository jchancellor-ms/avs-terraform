#creates an active/passive vpn gateway for configuration 
resource "azurerm_public_ip" "gatewaypip_1" {
  name                = var.vpn_pip_name_1
  resource_group_name = var.rg_name
  location            = var.rg_location
  allocation_method   = "Dynamic"
  sku                 = "Basic"
}

resource "azurerm_virtual_network_gateway" "gateway" {
  name                = var.vpn_gateway_name
  resource_group_name = var.rg_name
  location            = var.rg_location

  type       = "Vpn"
  vpn_type   = "RouteBased"
  sku        = var.vpn_gateway_sku
  generation = "Generation2"

  active_active = false
  enable_bgp    = true

  bgp_settings {
    asn = 65516
  }

  ip_configuration {
    name                          = "active_1"
    public_ip_address_id          = azurerm_public_ip.gatewaypip_1.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = var.gateway_subnet_id
  }
}

