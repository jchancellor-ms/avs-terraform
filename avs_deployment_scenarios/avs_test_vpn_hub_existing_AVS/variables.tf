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

variable "subnets" {
  type = list(object({
    name           = string
    address_prefix = list(string)
  }))
}

variable "expressroute_gateway_sku" {
  type        = string
  description = "The sku for the AVS expressroute gateway"
  default     = "Standard"
}

variable "vpn_gateway_sku" {
  type        = string
  description = "The sku for the AVS vpn gateway"
  default     = "VpnGw2"
}

variable "asn" {
  type        = number
  description = "The ASN for bgp on the VPN gateway"
  default     = "65515"
}

variable "email_addresses" {
  type        = list(string)
  description = "A list of email addresses where service health alerts will be sent"
}

variable "tags" {
  type        = map(string)
  description = "List of the tags that will be assigned to each resource"
}

variable "sddc_name" {
  type        = string
  description = "Name of the existing private cloud"
}

variable "sddc_rg_name" {
  type        = string
  description = "resource group name of the existing private cloud"
}