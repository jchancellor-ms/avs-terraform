
######################################################################################################################
# Build and configure the logstash vm
######################################################################################################################


#generate the cloud init config file
data "template_file" "configure_logstash" {
  template = file("${path.module}/templates/configure_logstash.yaml")

  vars = {
    eventHubConnectionString                    = var.logstash_values.eventHubConnectionString
    eventHubConsumerGroupName                   = var.logstash_values.eventHubConsumerGroupName
    eventHubInputStorageAccountConnectionString = var.logstash_values.eventHubInputStorageAccountConnectionString
    lawPluginAppId                              = var.logstash_values.lawPluginAppId
    lawPluginAppSecret                          = var.logstash_values.lawPluginAppSecret
    lawPluginTenantId                           = var.logstash_values.lawPluginTenantId
    lawPluginDataCollectionEndpointURI          = var.logstash_values.lawPluginDataCollectionEndpointURI
    lawPluginDcrImmutableId                     = var.logstash_values.lawPluginDcrImmutableId
    lawPluginDcrStreamName                      = var.logstash_values.lawPluginDcrStreamName
  }
}

data "template_cloudinit_config" "config" {
  gzip          = false
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.configure_logstash.rendered
  }
}

resource "random_password" "admin_password" {
  length  = 20
  special = false
  upper   = true
  lower   = true
}

resource "azurerm_network_interface" "logstash_nic" {
  name                = "${var.vm_name}-nic-1"
  location            = var.rg_location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.logstash_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "logstash_vm" {
  name                            = var.vm_name
  resource_group_name             = var.rg_name
  location                        = var.rg_location
  size                            = var.vm_sku #"Standard_E2as_v5"
  admin_username                  = "azureuser"
  admin_password                  = random_password.admin_password.result
  disable_password_authentication = false
  custom_data                     = data.template_cloudinit_config.config.rendered

  network_interface_ids = [
    azurerm_network_interface.logstash_nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
}

#write secret to keyvault
resource "azurerm_key_vault_secret" "admin_password" {
  name         = "${var.vm_name}-azureuser-password"
  value        = random_password.admin_password.result
  key_vault_id = var.key_vault_id
}

