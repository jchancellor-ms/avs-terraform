#create a test resource group
#Create the Network objects resource group
resource "azurerm_resource_group" "greenfield_test_spoke" {
  name     = var.rg_name
  location = var.rg_location
}

#create vnet
module "avs_spoke_virtual_network" {
  source = "../../modules/avs_vnet_variable_subnets"

  rg_name            = azurerm_resource_group.greenfield_test_spoke.name
  rg_location        = azurerm_resource_group.greenfield_test_spoke.location
  vnet_name          = var.vnet_name
  vnet_address_space = var.vnet_address_space
  subnets            = var.subnets
  tags               = var.tags
}


#create UDR for each subnet with 0/0 pointing to the firewall
#create UDR for NVA subnet disabling route propogation
resource "azurerm_route_table" "this" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  name                          = "${each.value.name}-udr"
  location                      = azurerm_resource_group.greenfield_test_spoke.location
  resource_group_name           = azurerm_resource_group.greenfield_test_spoke.name
  disable_bgp_route_propagation = true

  route {
    name                   = "default_to_firewall"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "this" {
  for_each = { for subnet in var.subnets : subnet.name => subnet }

  subnet_id      = module.avs_spoke_virtual_network.subnet_ids[each.value.name].id
  route_table_id = azurerm_route_table.this[each.value.name].id
}


#create peering relationships (use hub gateway/ars)

data "azurerm_virtual_network" "hub_vnet" {
  name                = var.hub_vnet_name
  resource_group_name = var.hub_rg_name
}

resource "azurerm_virtual_network_peering" "hub_owned_peer" {
  name                      = "${var.vnet_name}-link"
  resource_group_name       = var.hub_rg_name
  virtual_network_name      = var.hub_vnet_name
  remote_virtual_network_id = module.avs_spoke_virtual_network.vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "spoke_owned_peer" {
  name                      = "${var.hub_vnet_name}-link"
  resource_group_name       = azurerm_resource_group.greenfield_test_spoke.name
  virtual_network_name      = module.avs_spoke_virtual_network.vnet_name
  remote_virtual_network_id = data.azurerm_virtual_network.hub_vnet.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = true
}

#create test vm
resource "random_password" "admin_password" {
  length  = 20
  special = false
  upper   = true
  lower   = true
}

resource "azurerm_network_interface" "testvm_nic" {
  name                = "${var.vm_name}-nic-1"
  location            = azurerm_resource_group.greenfield_test_spoke.location
  resource_group_name = azurerm_resource_group.greenfield_test_spoke.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = module.avs_spoke_virtual_network.subnet_ids["VMSubnet"].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "testvm" {
  name                            = var.vm_name
  resource_group_name             = azurerm_resource_group.greenfield_test_spoke.name
  location                        = azurerm_resource_group.greenfield_test_spoke.location
  size                            = "Standard_B2s"
  admin_username                  = "azureuser"
  admin_password                  = random_password.admin_password.result
  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.testvm_nic.id,
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
  name         = "${var.vm_name}-azureuser-password"
  value        = random_password.admin_password.result
  key_vault_id = var.key_vault_id
}
