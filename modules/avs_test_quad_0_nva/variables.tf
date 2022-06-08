variable "rg_name" {
  type        = string
  description = "Resource Group Name where the nva is deployed"
}

variable "rg_location" {
  type        = string
  description = "Resource Group location"
  default     = "westus2"
}

variable "nva_subnet_id" {
  type        = string
  description = "subnet where the NVA will be deployed"
}

variable "nva_name" {
  type        = string
  description = "name for the bird nva"
}

variable "azfw_private_ip" {
  type        = string
  description = "azure firewall private ip to use for the quad 0 route"
}

variable "nva_asn" {
  type        = number
  description = "ASN number assigned to the route propogator"
  default     = 55555
}

variable "route_server" {
  description = "the route server details output from the route server virtual hub"
}

variable "key_vault_id" {
  type        = string
  description = "the resource id for the keyvault where the password will be stored"
}