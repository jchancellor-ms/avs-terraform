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
  description = "name for the frr nva"
}

variable "key_vault_id" {
  type        = string
  description = "the resource id for the keyvault where the password will be stored"
}
/*
variable "tf_template_github_source" {

}
variable "nsxt_root" {
  
}
variable "t1_gateway_display_name" {
  
}
variable "dhcp_profile_server_addresses" {
  
}
variable "vm_segment_display_name " {
  
}
variable "vm_segment_cidr_prefix " {
  
}
variable "vm_segment_dhcp_range " {
  
}
variable "dhcp_profile_server_addresses" {
  
}
variable "avs_dns_forwarder_address" {
  
}
variable "ovf_template_url" {
  
}
variable "nsx_ip" {
  
}
variable "nsx_user" {
  
}
variable "nsx_password" {
  
}
variable "vsphere_ip" {
  
}
variable "vsphere_user" {
  
}
variable "vsphere_password " {
  
}
*/