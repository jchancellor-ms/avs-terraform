variable "rg_name" {
  type        = string
  description = "Resource Group Name where the jumpbox is deployed"
}

variable "rg_location" {
  type        = string
  description = "Resource Group location"
  default     = "westus2"
}

variable "vnet_name" {
  type        = string
  description = "azure resource name for the spoke vnet"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space summaries for the spoke Vnet"
}

variable "subnets" {
  type = list(object({
    name           = string
    address_prefix = list(string)
  }))
}

variable "tags" {
  type        = map(string)
  description = "List of the tags that will be assigned to each resource"
}

variable "hub_vnet_name" {
  type        = string
  description = "azure resource name for the hub vnet"
}

variable "hub_rg_name" {
  type        = string
  description = "Resource Group Name where the hub vnet is deployed"
}

variable "vm_name" {
  type        = string
  description = "name for the test vm"
}

variable "key_vault_id" {
  type        = string
  description = "the resource id for the keyvault where the password will be stored"
}

variable "firewall_private_ip_address" {
  type        = string
  description = "The private IP address of the firewall target for the spoke default routes"
}