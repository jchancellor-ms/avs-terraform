
resource "random_password" "shared_key" {
  length  = 20
  special = false
  upper   = true
  lower   = true
}

resource "random_string" "namestring" {
  length  = 4
  special = false
  upper   = false
  lower   = true
}

resource "azurerm_virtual_network_gateway_connection" "avs-to-on-prem" {
  name                = "avs-to-on-prem-${var.prefix}-${random_string.namestring.result}"
  location            = var.rg_location_on_prem
  resource_group_name = var.rg_name_on_prem

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = var.on_prem_gateway_id
  peer_virtual_network_gateway_id = var.avs_gateway_id
  enable_bgp                      = true

  shared_key = random_password.shared_key.result
}

resource "azurerm_virtual_network_gateway_connection" "on-prem-to-avs" {
  name                = "on-prem-to-avs-${var.prefix}-${random_string.namestring.result}"
  location            = var.rg_location_avs
  resource_group_name = var.rg_name_avs

  type                            = "Vnet2Vnet"
  virtual_network_gateway_id      = var.avs_gateway_id
  peer_virtual_network_gateway_id = var.on_prem_gateway_id
  enable_bgp                      = true

  shared_key = random_password.shared_key.result
}

resource "azurerm_key_vault_secret" "vpn_shared_key" {
  name         = "on-prem-to-avs-vpn-shared-key-${var.prefix}"
  value        = random_password.shared_key.result
  key_vault_id = var.key_vault_id
}