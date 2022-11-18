module "avs_vmware_create_new_t1_gateway" {
  source                  = "../avs_vmware_create_new_t1_gateway"
  nsxt_root               = var.nsxt_root
  t1_gateway_display_name = var.t1_gateway_display_name
  dhcp_profile            = var.dhcp_profile
}

module "avs_vmware_create_new_segment" {
  source          = "../avs_vmware_create_new_segment"
  nsxt_root       = var.nsxt_root
  vm_segment      = var.vm_segment
  t1_gateway_path = module.avs_vmware_create_new_t1_gateway.t1_gateway_path

  depends_on = [
    module.avs_vmware_create_new_t1_gateway
  ]
}

resource "time_sleep" "wait_90_seconds" {
  depends_on      = [module.avs_vmware_create_new_segment]
  create_duration = "90s"
}

module "avs_vmware_create_test_vm" {
  source                       = "../avs_vmware_create_test_vm"
  vsphere_datacenter           = var.vsphere_datacenter
  vsphere_datastore            = var.vsphere_datastore
  ovf_content_library_name     = var.ovf_content_library_name
  ovf_template_name            = var.ovf_template_name
  ovf_template_description     = var.ovf_template_description
  ovf_template_url             = var.ovf_template_url
  vsphere_cluster              = var.vsphere_cluster
  network_segment_display_name = module.avs_vmware_create_new_segment.vm_segment_display_name
  vm_name                      = var.vm_name

  depends_on = [
    time_sleep.wait_90_seconds
  ]
}
