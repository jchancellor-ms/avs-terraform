output "vpn_gateway_id" {
  value = azurerm_virtual_network_gateway.gateway.id
}

output "vpn_gateway_pip_1" {
  value = azurerm_public_ip.gatewaypip_1.ip_address
}

output "vpn_gateway_pip_2" {
  value = azurerm_public_ip.gatewaypip_2.ip_address
}