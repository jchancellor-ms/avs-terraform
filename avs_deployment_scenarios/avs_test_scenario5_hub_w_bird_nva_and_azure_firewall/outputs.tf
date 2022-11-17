output "nva_asn" {
  value = var.nva_asn
}

/*
output "private_cloud_id" {
    value = data.azurerm_vmware_private_cloud.test-sddc.id
}
*/
output "firewall_policy_id" {
  value = module.avs_azure_firewall.firewall_policy_id
}


output "virtual_router_ips" {
  value = module.avs_routeserver.virtual_router_ips
}

#output resource groups
output "hub_resource_group" {
  value = azurerm_resource_group.hub_network_rg
}

#output expressRoute gateway id
output "hub_gateway_id" {
  value = module.avs_expressroute_gateway.expressroute_gateway_id
}

output "vnet_name" {
  value = local.vnet_name
}

output "vnet_id" {
  value = module.avs_hub_virtual_network.vnet_id
}