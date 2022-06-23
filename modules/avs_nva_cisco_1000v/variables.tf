variable "rg_name" {
  type        = string
  description = "The azure resource name for the resource group"
}

variable "rg_location" {
  description = "Resource Group region location"
  default     = "westus2"
}


variable "asn" {
  type        = string
  description = "ASN value used for the Cisco CSR "
}

variable "router_id" {
  type        = string
  description = "RouterID value for the Cisco CSRs"
}

variable "fw_ars_ips" {
  type        = list(string)
  description = "Ip values for the route server in the firewall vnet"
}
/*
variable "fw_vnet_subnet" {
  type = string
  description = "The vnet subnet for the firewall vnet"
}

variable "fw_vnet_mask" {
    type = string
    description = "subnet mask for the firewall vnet"
}

variable "fw_vnet_gateway" {
    type = string
    description = "the gateway address for the firewall vnet"
}
*/
variable "avs_ars_ips" {
  type        = list(string)
  description = "Ip values for the route server in the avs connected vnet"
}
/*
variable "avs_vnet_subnet" {
  type = string
  description = "The vnet subnet for the avs vnet"
}

variable "avs_vnet_mask" {
    type = string
    description = "subnet mask for the avs vnet"
}

variable "avs_vnet_gateway" {
    type = string
    description = "the gateway address for the avs vnet"
}
*/
variable "csr_fw_facing_subnet_gw" {
  type        = string
  description = "the gateway address for the csr subnet facing the firewall vnet"
}

variable "csr_avs_facing_subnet_gw" {
  type        = string
  description = "the gateway address for the csr subnet facing AVS"
}

variable "avs_network_subnet" {
  type        = string
  description = "the subnet for the AVS vnet without the mask"
}

variable "avs_network_mask" {
  type        = string
  description = "the mask for the AVS vnet. Typically a /22 mask value"
}

variable "node0_name" {
  type        = string
  description = "the vmname for the node0 CSR"
}

variable "node1_name" {
  type        = string
  description = "the vmname for the node0 CSR"
}

variable "fw_facing_subnet_id" {
  type        = string
  description = "the Azure resource id for the CSR subnet facing the firewall"
}

variable "avs_facing_subnet_id" {
  type        = string
  description = "the Azure resource id for the CSR subnet facing AVS"
}

variable "keyvault_id" {
  type        = string
  description = "keyvault where the passwords are being stored"
}

variable "avs_hub_replacement_asn" {
  type        = string
  description = "Dummy ASN used to replace the ASN from the AVS hub to avoid routing loops"
}

variable "fw_hub_replacement_asn" {
  type        = string
  description = "Dummy ASN used to replace the ASN from the AVS hub to avoid routing loops"
}