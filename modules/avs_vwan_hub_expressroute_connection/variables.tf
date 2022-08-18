variable "route_table_id" {
  type        = string
  description = "The Azure resource id for the default route table in the VWAN hub"
  default     = "null"
}

variable "express_route_gateway_id" {
  type        = string
  description = "The azure resource id for the express route gateway in the VWAN hub"
}

variable "express_route_connection_name" {
  type        = string
  description = "The azure resource name for the express route connection to the AVS private cloud"
}

variable "express_route_circuit_peering_id" {
  type        = string
  description = "The peering id for the AVS Private Cloud Express Route circuit"
}

variable "express_route_authorization_key" {
  type        = string
  description = "The authorization key for connecting the AVS private cloud express route circuit to the gateway"
}

variable "all_branch_traffic_through_firewall" {
  type        = bool
  description = "This flag determines whether to enable the AVS expressroute internet connectivity through the virtual hub firewall if one has been deployed."
  default     = false
}

variable "azure_firewall_id" {
  type        = string
  description = "The firewall ID associated to this hub when it is a secure hub"
  default     = "null"
}