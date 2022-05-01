output "vnet_id" {
  value = azurerm_virtual_network.network.id
}

output "gateway_subnet_id" {
  value = azurerm_subnet.gateway_subnet.id
}

output "route_server_subnet_id" {
  value = azurerm_subnet.route_server_subnet.id
}

