variable "prefix" {
  type        = string
  description = "Simple prefix used for naming convention prepending"
}

variable "region" {
  type        = string
  description = "Deployment region for the new AVS private cloud resources"
}

variable "tags" {
  type        = map(string)
  description = "List of the tags that will be assigned to each resource"
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

variable "sddc_name" {
  type        = string
  description = "Name of the existing private cloud"
}

variable "sddc_rg_name" {
  type        = string
  description = "resource group name of the existing private cloud"
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

variable "nva_asn" {
  type        = number
  description = "ASN number assigned to the route propogator"
  default     = 55555
}

variable "nva_routing_prefixes" {
  type        = list(string)
  description = "A list of prefixes to publish routes through the firewall IP address"
}

/*
variable "globalreach_circuit_id" {
  type        = string
  description = "the Azure ID of the expressRoute circuit AVS will connect to with global reach"
}

variable "globalreach_authkey" {
  type        = string
  description = "auth key for the global reach connection for expressroute"
}
*/