variable "vnet_name" {
  type        = string
  description = "The azure resource name for the hub vnet"
}
variable "vnet_address_space" {
  type        = list(string)
  description = "List of CIDR ranges assigned to the hub VNET.  Typically one larger range."
}
variable "rg_name" {
  type        = string
  description = "The azure resource name for the resource group"
}
variable "rg_location" {
  description = "Resource Group region location"
  default     = "westus2"
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

variable "tags" {
  type        = map(string)
  description = "List of the tags that will be assigned to each resource"
}