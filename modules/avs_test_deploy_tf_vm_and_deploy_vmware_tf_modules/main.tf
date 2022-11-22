locals {
  #create the vmware nsx and vsphere credential variables
  vmware_creds = {
    nsx = {
      ip       = split("/", data.azurerm_vmware_private_cloud.sddc_on_prem_2.nsxt_manager_endpoint)[2]
      user     = jsondecode(data.azapi_resource_action.sddc_on_prem_2_creds.output).nsxtUsername
      password = jsondecode(data.azapi_resource_action.sddc_on_prem_2_creds.output).nsxtPassword
    }
    vsphere = {
      ip       = split("/", data.azurerm_vmware_private_cloud.sddc_on_prem_2.vcsa_endpoint)[2]
      user     = jsondecode(data.azapi_resource_action.sddc_on_prem_2_creds.output).vcenterUsername
      password = jsondecode(data.azapi_resource_action.sddc_on_prem_2_creds.output).vcenterPassword
    }
  }
  #create the state storage variable map for consumption by the vmware terraform
  vmware_state_storage = {
    resource_group_name = var.vmware_state_storage.resource_group_name
    account_name        = var.vmware_state_storage.account_name
    container_name      = var.vmware_state_storage.container_name
    key_name            = var.vmware_state_storage.key_name
    subscription_id     = azurerm_subscription.current.subscription_id
    tenant_id           = azurerm_user_assigned_identity.vm_managed_identity.tenant_id
    client_id           = azurerm_user_assigned_identity.vm_managed_identity.client_id
  }

  #create locals for module naming 
  role_assigment_name   = "vmware-tfstate-${random_string.namestring.result}"
  managed_identity_name = "vmware-state-access-${random_string.namestring.result}"
}

#create a random string for naming
resource "random_string" "namestring" {
  length  = 4
  special = false
  upper   = false
  lower   = true
}

#these data providers populate the SDDC credentials for connecting to nsx and vsphere using the sddc name and rg
#get all of the SDDC details
data "azurerm_vmware_private_cloud" "sddc" {
  name                = var.sddc_name
  resource_group_name = var.sddc_rg_name
}

#get SDDC credentials for use with the VMware provider
data "azapi_resource_action" "sddc_creds" {
  type                   = "Microsoft.AVS/privateClouds@2021-12-01"
  resource_id            = data.azurerm_vmware_private_cloud.sddc.id
  action                 = "listAdminCredentials"
  response_export_values = ["*"]
}

#these data providers get the state storage details for use by the vmware terraform deployment
data "azurerm_storage_account" "vmware_state_storage_account" {
  name                = var.vmware_state_storage.account_name
  resource_group_name = var.vmware_state_storage.resource_group_name
}

#get storage contributor role definition id (consider changing this to Azure AD and storage blob data contributor in the future)
data "azurerm_role_definition" "storage_contributor" {
  name = "Storage Account Contributor"
}

#get the deployment subscription details
data "azurerm_subscription" "current" {
}

### Create the deployment resources ##################################################

#create a User-Assigned managed Identity 
resource "azurerm_user_assigned_identity" "vm_managed_identity" {
  location            = var.rg_location
  name                = local.managed_identity_name
  resource_group_name = var.rg_name
}

#provision the managed identity of the vm to have access to the storage account
resource "azurerm_role_assignment" "vm_managed_identity_vmware_state_storage" {
  name               = local.role_assigment_name
  scope              = data.azurerm_storage_account.vmware_state_storage_account.id
  role_definition_id = data.azurerm_role_definition.storage_contributor.id
  principal_id       = azurerm_user_assigned_identity.vm_managed_identity.id
}

#generate the cloud init config file
data "template_file" "vmware_config" {
  template = file("${path.module}/templates/vmware_cloud_init.yaml")

  vars = {
    tf_template_github_source = var.tf_template_github_source
    #vmware provider details
    vmware_creds = var.vmware_creds
    #Azure state storage details
    vmware_state_storage = var.vmware_state_storage
    #deployment details
    vmware_deployment = var.vmware_deployment
  }
}

#base64 encode it for cloudinit
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
  name                = "${var.tf_vm_name}-nic-1"
  location            = var.rg_location
  resource_group_name = var.rg_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.tf_vm_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

#create the linux host using the cloud-init script
resource "azurerm_linux_virtual_machine" "vmware_terraform_host" {
  name                            = var.tf_vm_name
  resource_group_name             = var.rg_name
  location                        = var.rg_location
  size                            = "Standard_B2ms"
  admin_username                  = "azureuser"
  admin_password                  = random_password.admin_password.result
  disable_password_authentication = false
  custom_data                     = data.template_cloudinit_config.config.rendered

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.vm_managed_identity.id]
  }

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
    sku       = "22_04-LTS"
    version   = "latest"
  }

}

#write secret to keyvault
resource "azurerm_key_vault_secret" "admin_password" {
  name         = "${var.tf_vm_name}-azureuser-password"
  value        = random_password.admin_password.result
  key_vault_id = var.key_vault_id
}

