output "vwan_hub_id" {
  value = module.avs_vwan_hub_with_express_route_gateway.vwan_hub_id
}

output "vwan_hub_name" {
  value = local.vwan_hub_name
}

output "vwan_hub_resource_group_name" {
  value = azurerm_resource_group.greenfield_network.name
}

output "express_route_gateway_id" {
  value = module.avs_vwan_hub_with_express_route_gateway.express_route_gateway_id
}