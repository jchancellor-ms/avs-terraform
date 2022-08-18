output "vwan_hub_id" {
  value = azurerm_virtual_hub.vwan_hub.id
}

output "express_route_gateway_id" {
  value = azurerm_express_route_gateway.vwan_express_route_gateway.id
}

output "default_route_table_id" {
  value = azurerm_virtual_hub.vwan_hub.default_route_table_id
}