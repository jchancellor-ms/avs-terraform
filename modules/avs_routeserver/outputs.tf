output "routeserver_id" {
  value = azurerm_virtual_hub_ip.routeserver.id
}

output "routeserver_details" {
  value = azurerm_virtual_hub.virtual_hub
}

output "virtual_hub_id" {
  value = azurerm_virtual_hub.virtual_hub.id
}

output "virtual_router_ips" {
  value = azurerm_virtual_hub.virtual_hub.virtual_router_ips
}

output "virtual_router_asn" {
  value = azurerm_virtual_hub.virtual_hub.virtual_router_asn
}