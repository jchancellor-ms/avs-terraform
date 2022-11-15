locals {

}

resource "random_password" "userpass" {
  length           = 20
  special          = true
  override_special = "_-!."
  min_lower        = 2
  min_numeric      = 2
  min_upper        = 2
  min_special      = 2
}

resource "azurerm_key_vault_secret" "vmpassword" {
  name         = "${var.vm_name_1}-password"
  value        = random_password.userpass.result
  key_vault_id = var.key_vault_id
  depends_on   = [var.key_vault_id]
}

##################################################################################
# Configure the first DC
##################################################################################
resource "azurerm_network_interface" "testnic" {
  name                = "${var.vm_name_1}-nic-1"
  location            = var.rg_location
  resource_group_name = var.rg_name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip_address_1
  }
}

resource "azurerm_windows_virtual_machine" "primary" {
  name                     = var.vm_name_1
  resource_group_name      = var.rg_name
  location                 = var.rg_location
  size                     = var.vm_sku
  admin_username           = "azureuser"
  admin_password           = random_password.userpass.result
  license_type             = "Windows_Server"
  enable_automatic_updates = true
  patch_mode               = "AutomaticByOS"


  network_interface_ids = [
    azurerm_network_interface.testnic.id,
  ]
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

data "template_file" "configure_primary_dc" {
  template = file("${path.module}/configure_primary_dc.ps1")

  vars = {
    password                      = random_password.userpass.result
    active_directory_domain       = var.active_directory_domain
    active_directory_netbios_name = (split(".", var.active_directory_domain))[0]
  }
}

#TODO: Consider moving all of this to DSC instead of powershell 
resource "azurerm_virtual_machine_extension" "configure_primary_dc" {
  name                 = "configure_primary_dc"
  virtual_machine_id   = azurerm_windows_virtual_machine.primary.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  protected_settings = <<PROTECTED_SETTINGS
    {
        "commandToExecute": "powershell -command \"[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String('${base64encode(data.template_file.configure_primary_dc.rendered)}')) | Out-File -filepath configure_primary_dc.ps1\" && powershell -ExecutionPolicy Unrestricted -File configure_primary_dc.ps1"
    }
PROTECTED_SETTINGS

}

##################################################################################
# Configure the second DC
##################################################################################
# TODO: Update this to add a second DC 