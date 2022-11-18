module "avs_vmware_create_new_t1_gateway" {
  source                  = "../avs_vmware_create_new_t1_gateway"
  nsxt_root               = var.nsxt_root
  t1_gateway_display_name = var.t1_gateway_display_name
  dhcp_profile            = var.dhcp_profile
  nsx_ip                  = var.nsx_ip
  nsx_user                = var.nsx_user
  nsx_password            = var.nsx_password
}

module "avs_vmware_create_new_segment" {
  source          = "../avs_vmware_create_new_segment"
  nsxt_root       = var.nsxt_root
  vm_segment      = var.vm_segment
  t1_gateway_path = module.avs_vmware_create_new_t1_gateway.t1_gateway_path
  nsx_ip          = var.nsx_ip
  nsx_user        = var.nsx_user
  nsx_password    = var.nsx_password
}

module "avs_vmware_create_test_vm" {
  source                       = "../avs_vmware_create_test_vm"
  vsphere_datacenter           = var.vsphere_datacenter
  vsphere_datastore            = var.vsphere.datastore
  ovf_content_library_name     = var.ovf_content_library_name
  ovf_template_name            = var.ovf_template_name
  ovf_template_description     = var.ovf_template_description
  ovf_template_url             = var.ovf_template_url
  vsphere_cluster              = var.vsphere_cluster
  network_segment_display_name = module.avs_vmware_create_new_segment.vm_segment_display_name
  vsphere_ip                   = var.vsphere_ip
  vsphere_user                 = var.vsphere_user
  vsphere_password             = var.vsphere_password
}
