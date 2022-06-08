output "vpn_gateway_id" {
  value = module.on_prem_vpn_gateway.vpn_gateway_id
}

output "vpn_gateway_pip_1" {
  value = module.on_prem_vpn_gateway.vpn_gateway_pip_1
}

output "resource_group_name" {
  value = azurerm_resource_group.test_on_prem.name
}

output "resource_group_location" {
  value = azurerm_resource_group.test_on_prem.location
}

output "vpn_gateway_bgp_peering_addresses" {
  value = module.on_prem_vpn_gateway.vpn_gateway_bgp_peering_addresses
}

output "vpn_gateway_asn" {
  value = module.on_prem_vpn_gateway.vpn_gateway_asn
}

output "keyvault_id" {
  value = module.on_prem_keyvault_with_access_policy.keyvault_id
}

output "deploy_id" {
  value = random_string.namestring.result
}