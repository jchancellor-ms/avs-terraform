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

variable "bastion_subnet_prefix" {
  type        = list(string)
  description = "A list of subnet prefix CIDR values used for the bastion subnet address space"
}

variable "jumpbox_subnet_prefix" {
  type        = list(string)
  description = "A list of subnet prefix CIDR values used for the jumpbox subnet address space"
}

variable "vpn_gateway_sku" {
  type        = string
  description = "The sku for the AVS vpn gateway"
  default     = "VpnGw2"
}

variable "jumpbox_sku" {
  type        = string
  description = "The sku for the jumpbox vm"
  default     = "Standard_D2as_v4"
}

variable "admin_username" {
  type        = string
  description = "The username for the jumpbox admin login"
}

variable "tags" {
  type        = map(string)
  description = "List of the tags that will be assigned to each resource"
}