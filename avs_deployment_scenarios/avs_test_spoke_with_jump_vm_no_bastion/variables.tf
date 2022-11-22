variable "prefix" {
  type        = string
  description = "Simple prefix used for naming convention prepending"
}

variable "region" {
  type        = string
  description = "Deployment region for the new AVS private cloud resources"
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

variable "hub_vnet_name" {
  type        = string
  description = "Name of the hub vnet this spoke vNet will connect to"
}

variable "hub_rg_name" {
  type        = string
  description = "Name of the hub vnet this spoke vNet will connect to"
}

variable "jumpbox_spoke_vnet_address_space" {
  type        = list(string)
  description = "Address space summaries for the spoke Vnet"
}

variable "jumpbox_subnet_prefix" {
  type        = string
  description = "A subnet prefix CIDR value used for the jumpbox subnet address space"
}

variable "keyvault_id" {
  type        = string
  description = "The id of the hub keyvault used for storing the jump password"
}

variable "firewall_ip" {
  type        = string
  description = "firewall ip for next hop for the subnets in the spoke"
}