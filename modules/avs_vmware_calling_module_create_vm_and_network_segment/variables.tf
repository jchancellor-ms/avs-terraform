variable "deployment" {
  description = "Map object containing all of the input values for the module"
}

variable "vsphere_creds" {
  description = "Map object containing the vsphere login credentials"
  sensitive   = true
}
variable "vmware_deployment" {
  description = "map of values for the terraform modules being built on vsphere and nsx"
}