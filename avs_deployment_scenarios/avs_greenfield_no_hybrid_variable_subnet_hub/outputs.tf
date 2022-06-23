output "subnet_ids" {
  value = module.avs_hub_virtual_network.subnet_ids
}

output "network_rg_name" {
  value = local.network_rg_name
}

output "network_rg_location" {
  value = var.region
}

output "avs_network_cidr" {
  value = var.avs_network_cidr
}

output "subnets" {
  value = var.subnets
}

output "hub_vnet_name" {
  value = local.vnet_name
}

output "hub_vnet_id" {
  value = module.avs_hub_virtual_network.vnet_id
}

output "virtual_hub_id" {
  value = module.avs_routeserver.virtual_hub_id
}

output "ars_peer_ips" {
  value = module.avs_routeserver.routeserver_details.virtual_router_ips
}

output "keyvault_id" {
  value = module.avs_keyvault_with_access_policy.keyvault_id
}

output "deploy_prefix" {
  value = var.prefix
}