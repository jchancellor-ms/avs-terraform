
#generate the cloud init config file
data "template_file" "bird_config" {
  template = file("${path.module}/templates/bird_cloud_init.yaml")

  vars = {
    azfw_private_ip = var.azfw_private_ip
    nva_private_ip  = azurerm_network_interface.bird_nic.private_ip_address
    nva_asn         = var.nva_asn
    rs_asn          = var.route_server.virtual_router_asn
    rs_ip1          = var.route_server.virtual_router_ips[0]
    rs_ip2          = var.route_server.virtual_router_ips[1]
  }
}

data "template_cloudinit_config" "config" {
  gzip          = false
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.bird_config.rendered
  }
}

resource "random_password" "admin_password" {
  length  = 20
  special = false
  upper   = true
  lower   = true
}

resource "azurerm_network_interface" "bird_nic" {
  name                = "${var.nva_name}-nic-1"
  location            = var.rg_location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.nva_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "bird_route_generator" {
  name                            = var.nva_name
  resource_group_name             = var.rg_name
  location                        = var.rg_location
  size                            = "Standard_B1s"
  admin_username                  = "azureuser"
  admin_password                  = random_password.admin_password.result
  disable_password_authentication = false
  custom_data                     = data.template_cloudinit_config.config.rendered

  network_interface_ids = [
    azurerm_network_interface.bird_nic.id,
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

#create UDR for NVA subnet disabling route propogation
resource "azurerm_route_table" "nva_udr" {
  name                          = "${var.nva_name}-udr"
  location                      = var.rg_location
  resource_group_name           = var.rg_name
  disable_bgp_route_propagation = true
}

resource "azurerm_subnet_route_table_association" "nva_subnet_rt" {
  subnet_id      = var.nva_subnet_id
  route_table_id = azurerm_route_table.nva_udr.id
}

#create routeserver peering
resource "azurerm_virtual_hub_bgp_connection" "nva_vm" {
  name           = "${var.nva_name}-bgp-connection"
  virtual_hub_id = var.virtual_hub_id
  peer_asn       = var.nva_asn
  peer_ip        = azurerm_network_interface.bird_nic.private_ip_address
}