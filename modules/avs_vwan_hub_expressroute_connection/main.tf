
resource "azurerm_express_route_connection" "avs_private_cloud_connection" {
  name                             = var.express_route_connection_name
  express_route_gateway_id         = var.express_route_gateway_id
  express_route_circuit_peering_id = var.express_route_circuit_peering_id
  authorization_key                = var.express_route_authorization_key
  enable_internet_security         = var.all_branch_traffic_through_firewall #publish a default route to the internet through Azure Firewall when true
}
