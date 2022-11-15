output "sddc_id" {
  value = module.avs_private_cloud.sddc_id
}

output "sddc_express_route_id" {
  value = module.avs_private_cloud.sddc_express_route_id
}

output "sddc_express_route_private_peering_id" {
  value = module.avs_private_cloud.sddc_express_route_private_peering_id
}

output "sddc_vcsa_endpoint" {
  value = module.avs_private_cloud.sddc_vcsa_endpoint
}

output "sddc_nsxt_manager_endpoint" {
  value = module.avs_private_cloud.sddc_nsxt_manager_endpoint
}

output "sddc_hcx_cloud_manager_endpoint" {
  value = module.avs_private_cloud.sddc_hcx_cloud_manager_endpoint
}

output "sddc_provisioning_subnet_cidr" {
  value = module.avs_private_cloud.sddc_provisioning_subnet_cidr
}

output "network_resource_group_name" {
  value = azurerm_resource_group.greenfield_network.name
}

output "network_resource_group_location" {
  value = azurerm_resource_group.greenfield_network.location
}

output "vnet_name" {
  value = local.vnet_name
}