
output "vpn_gateway_id" {
  value = module.avs_vpn_gateway.vpn_gateway_id
}

output "vpn_gateway_pip_1" {
  value = module.avs_vpn_gateway.vpn_gateway_pip_1
}

output "vpn_gateway_pip_2" {
  value = module.avs_vpn_gateway.vpn_gateway_pip_2
}

output "vpn_gateway_bgp_peering_addresses" {
  value = module.avs_vpn_gateway.vpn_gateway_bgp_peering_addresses
}

output "vpn_gateway_asn" {
  value = module.avs_vpn_gateway.vpn_gateway_asn
}

output "network_resource_group_name" {
  value = azurerm_resource_group.greenfield_network.name
}

output "network_resource_group_location" {
  value = azurerm_resource_group.greenfield_network.location
}

output "prefix" {
  value = var.prefix
}

#TODO - duplicate, fix this 
output "network_rg_name" {
  value = local.network_rg_name
}

output "network_rg_location" {
  value = var.region
}

output "subnet_ids" {
  value = module.avs_hub_virtual_network.subnet_ids
}

output "routeserver_details" {
  value = module.avs_routeserver.routeserver_details
}

output "hub_vnet_name" {
  value = local.vnet_name
}