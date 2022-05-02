variable "prefix" {
  type        = string
  description = "Simple prefix used for naming convention prepending"
}

variable "region" {
  type        = string
  description = "Deployment region for the new AVS private cloud resources"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "List of CIDR ranges assigned to the hub VNET.  Typically one larger range."
}

variable "gateway_subnet_prefix" {
  type        = list(string)
  description = "A list of subnet prefix CIDR values used for the gateway subnet address space"
}

variable "route_server_subnet_prefix" {
  type        = list(string)
  description = "A list of subnet prefix CIDR values used for the route_server subnet address space"
}

variable "firewall_subnet_prefix" {
  type        = list(string)
  description = "A list of subnet prefix CIDR values used for the firewall subnet address space"
}

variable "expressroute_gateway_sku" {
  type        = string
  description = "The sku for the AVS expressroute gateway"
  default     = "Standard"
}

variable "sddc_sku" {
  type        = string
  description = "The sku value for the AVS SDDC management cluster nodes"
  default     = "av36"
}

variable "management_cluster_size" {
  type        = number
  description = "The number of nodes to include in the management cluster"
  default     = 3
}

variable "avs_network_cidr" {
  type        = string
  description = "The full /22 network CIDR range summary for the private cloud managed components"
}

variable "vpn_gateway_sku" {
  type        = string
  description = "The sku for the AVS vpn gateway"
  default     = "VpnGw2"
}

variable "firewall_sku_tier" {
  type        = string
  description = "Firewall Sku Tier - allowed values are Standard and Premium"
  default     = "Standard"
  validation {
    condition     = contains(["Standard", "Premium"], var.firewall_sku_tier)
    error_message = "Value must be Standard or Premium."
  }
}

variable "tags" {
  type        = map(string)
  description = "List of the tags that will be assigned to each resource"
}