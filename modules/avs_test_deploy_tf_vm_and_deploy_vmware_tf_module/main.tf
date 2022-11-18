
#generate the cloud init config file
data "template_file" "vmware_config" {
  template = file("${path.module}/templates/vmware_cloud_init.yaml")

  vars = {
    tf_template_github_source     = var.tf_template_github_source
    nsxt_root                     = var.nsxt_root
    t1_gateway_display_name       = var.t1_gateway_display_name
    dhcp_profile_server_addresses = var.dhcp_profile_server_addresses
    vm_segment_display_name       = var.vm_segment_display_name
    vm_segment_cidr_prefix        = var.vm_segment_cidr_prefix
    vm_segment_dhcp_range         = var.vm_segment_dhcp_range
    avs_dns_forwarder_address     = var.avs_dns_forwarder_address
    ovf_template_url              = var.ovf_template_url
    nsx_ip                        = var.nsx_ip
    nsx_user                      = var.nsx_user
    nsx_password                  = var.nsx_password
    vsphere_ip                    = var.vsphere_ip
    vsphere_user                  = var.vsphere_user
    vsphere_password              = var.vsphere_password
    vm_name                       = var.vm_name
  }

}

data "template_cloudinit_config" "config" {
  gzip          = false
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.vmware_config.rendered
  }
}

resource "random_password" "admin_password" {
  length  = 20
  special = false
  upper   = true
  lower   = true
}

resource "azurerm_network_interface" "vmware_nic" {
  name                = "${var.nva_name}-nic-1"
  location            = var.rg_location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.nva_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vmware_terraform_host" {
  name                            = var.nva_name
  resource_group_name             = var.rg_name
  location                        = var.rg_location
  size                            = "Standard_B2ms"
  admin_username                  = "azureuser"
  admin_password                  = random_password.admin_password.result
  disable_password_authentication = false
  custom_data                     = data.template_cloudinit_config.config.rendered

  network_interface_ids = [
    azurerm_network_interface.vmware_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }
}

#write secret to keyvault
resource "azurerm_key_vault_secret" "admin_password" {
  name         = "${var.nva_name}-azureuser-password"
  value        = random_password.admin_password.result
  key_vault_id = var.key_vault_id
}

