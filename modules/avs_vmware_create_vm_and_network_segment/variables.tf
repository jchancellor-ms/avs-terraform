variable "nsxt_root" {
  type        = string
  description = "AVS root value used in t0, edge, and transport overlay naming"
}

variable "t1_gateway_display_name" {
  type        = string
  description = "Display name for the new T1 gateway"
}

#check this
variable "dhcp_profile" {
  description = "map of strings used to create the dhcp profile"
}

#check this
variable "vm_segment" {
  description = "map of strings and maps with vm segment configuration details"
}

variable "vsphere_datacenter" {
  type        = string
  description = "Name of the vsphere datacenter where vm will be deployed"
  default     = "SDDC-Datacenter"
}

variable "vsphere_datastore" {
  type        = string
  description = "Name of the vsphere datastore where vm will be deployed"
  default     = "vsanDatastore"
}

variable "ovf_content_library_name" {
  type        = string
  description = "Name for the local content library where OVF's will be imported for VM deployment"
  default     = "ovfContentLibrary"
}

variable "ovf_template_name" {
  type        = string
  description = "Name for the OVF template being downloaded to the content library"
}

variable "ovf_template_description" {
  type        = string
  description = "Description for the OVF template being downloaded to the content library"
}

variable "vsphere_cluster" {
  type        = string
  description = "Name of the vsphere cluster where vm will be deployed"
  default     = "Cluster-1"
}

variable "ovf_template_url" {
  type        = string
  description = "URL of the OVA or OVF being used as the template for the VM"
}

variable "nsx_ip" {
  type        = string
  description = "NSX-T manager IP address"
}

variable "nsx_user" {
  description = "NSX-T administrator username"
  type        = string
  sensitive   = true
}

variable "nsx_password" {
  description = "NSX-T administrator password"
  type        = string
  sensitive   = true
}

variable "vsphere_ip" {
  description = "vsphere IP address"
  type        = string
  sensitive   = true
}
variable "vsphere_user" {
  description = "vsphere administrator username"
  type        = string
  sensitive   = true
}
variable "vsphere_password" {
  description = "vsphere administrator password"
  type        = string
  sensitive   = true
}
variable "vm_name" {
    type = string
    description = "name for the new test vm"
}