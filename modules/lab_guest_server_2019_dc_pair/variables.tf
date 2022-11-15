variable "rg_name" {
  type        = string
  description = "The azure resource name for the resource group"
}
variable "rg_location" {
  type        = string
  description = "Resource Group region location"
  default     = "westus2"
}
variable "vm_name_1" {
  type        = string
  description = "The azure resource name for the virtual machine"
}
variable "subnet_id" {
  type        = string
  description = "The resource ID for the subnet where the virtual machine will be deployed"
}
variable "vm_sku" {
  type        = string
  description = "The sku value for the virtual machine being deployed"
}
variable "key_vault_id" {
  type        = string
  description = "The resource ID for the key vault where the virtual machine secrets will be deployed"
}
variable "active_directory_domain" {
  type        = string
  description = "The full domain name for the domain being created"
}
variable "active_directory_netbios_name" {
  type        = string
  description = "The netbios name for the domain being created"
}
variable "private_ip_address_1" {
  type        = string
  description = "The static IP address of the domain controller which will be injected into DNS"
}
#variable "firewall_ip" {}
variable "ou_name" {
  type        = string
  description = "custom OU to create during DC build."
}
