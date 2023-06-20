# Created using instructions from article - https://learn.microsoft.com/en-us/azure/sentinel/connect-logstash-data-connection-rules#create-the-required-dcr-resources

#deploy a resource group
resource "azurerm_resource_group" "avs_log_processing" {
  name     = var.rg_name
  location = var.rg_location
}

########################################################################################
#Create an AD application registration service principal and password
########################################################################################
data "azuread_client_config" "current" {}

resource "azuread_application" "log_processing_principal" {
  display_name = var.avs_log_processing_service_principal_name
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "log_procesing_principal" {
  application_id               = azuread_application.log_processing_principal.application_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal_password" "log_procesing_principal" {
  service_principal_id = azuread_service_principal.log_procesing_principal.object_id
}

resource "azuread_application_password" "log_processing_principal" {
  application_object_id = azuread_application.log_processing_principal.object_id
}

########################################################################################
#Deploy the Event hub items
########################################################################################
#Deploy the event hub namespace
resource "azurerm_eventhub_namespace" "avs_log_processing" {
  name                = var.eventhub_namespace_name
  location            = azurerm_resource_group.avs_log_processing.location
  resource_group_name = azurerm_resource_group.avs_log_processing.name
  sku                 = "Standard"
  capacity            = var.eventhub_capacity

  tags = var.tags
}

#deploy the event hub 
resource "azurerm_eventhub" "avs_log_processing" {
  name                = var.eventhub_name
  namespace_name      = azurerm_eventhub_namespace.avs_log_processing.name
  resource_group_name = azurerm_resource_group.avs_log_processing.name
  partition_count     = var.eventhub_partition_count
  message_retention   = var.eventhub_message_retention_days
}
#deploy the authorization rule for the diagnostic setting
resource "azurerm_eventhub_namespace_authorization_rule" "avs_log_processing" {
  name                = var.diagnostic_eventhub_authorization_rule_name
  namespace_name      = azurerm_eventhub_namespace.avs_log_processing.name
  resource_group_name = azurerm_resource_group.avs_log_processing.name

  listen = true
  send   = true
  manage = true
}
#deploy the authorization rule for the plugin
resource "azurerm_eventhub_authorization_rule" "avs_log_processing" {
  name                = var.logstash_eventhub_authorization_rule_name
  namespace_name      = azurerm_eventhub_namespace.avs_log_processing.name
  resource_group_name = azurerm_resource_group.avs_log_processing.name

  listen = true
  send   = true
  manage = true
}
#deploy an eventhub consumer group for use by the logstash plugin
resource "azurerm_eventhub_consumer_group" "avs_log_processing" {
  name                = var.consumer_group_name
  namespace_name      = azurerm_eventhub_namespace.avs_log_processing.name
  eventhub_name       = azurerm_eventhub.avs_log_processing.name
  resource_group_name = azurerm_resource_group.avs_log_processing.name
}
#deploy a storage account for use by the eventhub plugin to maintain state
resource "azurerm_storage_account" "avs_log_processing" {
  name                     = var.plugin_storage_account_name
  resource_group_name      = azurerm_resource_group.avs_log_processing.name
  location                 = azurerm_resource_group.avs_log_processing.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
}
#######################################################################################
# Deploy a log analytics workspace and create a custom table for the logs
#######################################################################################
#Deploy the Log Analytics workspace
resource "azurerm_log_analytics_workspace" "avs_log_workspace" {
  name                = var.log_analytics_name
  location            = azurerm_resource_group.avs_log_processing.location
  resource_group_name = azurerm_resource_group.avs_log_processing.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

#create a custom table
resource "azapi_resource" "law_table" {
  name      = var.custom_table_name
  parent_id = azurerm_log_analytics_workspace.avs_log_workspace.id
  type      = "Microsoft.OperationalInsights/workspaces/tables@2022-10-01"
  body = jsonencode(
    {
      "properties" : {
        "schema" : {
          "name" : "${var.custom_table_name}",
          "columns" : [
            {
              "name" : "Facility",
              "type" : "string"
            },
            {
              "name" : "LogCreationTime",
              "type" : "datetime"
            },
            {
              "name" : "TimeGenerated",
              "type" : "datetime"
            },
            {
              "name" : "ResourceId",
              "type" : "string"
            },
            {
              "name" : "Severity",
              "type" : "string"
            },
            {
              "name" : "Message",
              "type" : "string"
            }
          ]
        }
      }
    }
  )
}

###########################################################################################################
# Create a data collection endpoint and data collection rule.  Authorize the service principal to the rule
###########################################################################################################

#Create the DCE
resource "azurerm_monitor_data_collection_endpoint" "avs_log_processing_dce" {
  name                          = var.data_collection_endpoint_name
  resource_group_name           = azurerm_resource_group.avs_log_processing.name
  location                      = azurerm_resource_group.avs_log_processing.location
  public_network_access_enabled = true
  description                   = "monitor_data_collection_endpoint for AVS log processing"
  tags                          = var.tags
}

#Create the DCR
resource "azurerm_monitor_data_collection_rule" "avs_log_processing_dcr" {
  name                        = var.data_collection_rule_name
  resource_group_name         = azurerm_resource_group.avs_log_processing.name
  location                    = azurerm_resource_group.avs_log_processing.location
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.avs_log_processing_dce.id

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.avs_log_workspace.id
      name                  = var.log_analytics_name
    }
  }

  data_flow {
    streams       = ["${var.custom_table_name}"]
    destinations  = ["${var.log_analytics_name}"]
    output_stream = var.custom_table_name
    transform_kql = "source"
  }

  data_sources {}

  stream_declaration {
    stream_name = var.custom_table_name
    column {
      name = "Facility"
      type = "string"
    }
    column {
      name = "LogCreationTime"
      type = "datetime"
    }
    column {
      name = "TimeGenerated"
      type = "datetime"
    }
    column {
      name = "ResourceId"
      type = "string"
    }
    column {
      name = "Severity"
      type = "string"
    }
    column {
      name = "Message"
      type = "string"
    }
  }

  description = "data collection rule example"
  tags        = var.tags
}

#Permission the DCR
resource "azurerm_role_assignment" "log_service_principal_dcr_assignment" {
  scope                = azurerm_monitor_data_collection_rule.avs_log_processing_dcr.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = azuread_service_principal.log_procesing_principal.object_id
}


#######################################################################################################################
# Configure a diagnostic setting on the private cloud to send the syslog data to the event hub
#######################################################################################################################

resource "azurerm_monitor_diagnostic_setting" "private_cloud_syslog" {
  name                           = var.diagnostics_setting_name
  target_resource_id             = var.private_cloud_resource_id
  eventhub_name                  = azurerm_eventhub.avs_log_processing.name
  eventhub_authorization_rule_id = azurerm_eventhub_namespace_authorization_rule.avs_log_processing.id

  enabled_log {
    category = "VMwareSyslog"

    retention_policy {
      enabled = false
    }
  }
}

#######################################################################################################################
# Create a keyvault for storing the vm passwords
#######################################################################################################################

#deploy a keyvault for central secret management
data "azurerm_client_config" "current" {
}

resource "azurerm_key_vault" "infra_vault" {
  name                            = var.keyvault_name
  location                        = azurerm_resource_group.avs_log_processing.location
  resource_group_name             = azurerm_resource_group.avs_log_processing.name
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  enabled_for_deployment          = true
  tenant_id                       = var.azure_ad_tenant_id
  soft_delete_retention_days      = 7
  purge_protection_enabled        = true
  sku_name                        = "standard"
  tags                            = var.tags
}

#set a wait timer to handle creation lag issues
resource "time_sleep" "wait_30_seconds" {
  depends_on = [azurerm_key_vault.infra_vault]

  create_duration = "30s"
}

resource "azurerm_key_vault_access_policy" "deployment_user_access" {
  key_vault_id = azurerm_key_vault.infra_vault.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Backup", "Recover", "Restore"
  ]

  depends_on = [
    time_sleep.wait_30_seconds
  ]

}


######################################################################################################################
# Build and configure the logstash vm. Includes a vnet and subnet 
######################################################################################################################


#generate the cloud init config file
data "template_file" "configure_logstash" {
  template = file("${path.module}/templates/configure_logstash.yaml")

  vars = {
    eventHubConnectionString                    = azurerm_eventhub_authorization_rule.avs_log_processing.primary_connection_string
    eventHubConsumerGroupName                   = azurerm_eventhub_consumer_group.avs_log_processing.name
    eventHubInputStorageAccountConnectionString = azurerm_storage_account.avs_log_processing.primary_connection_string
    lawPluginAppId                              = azuread_application.log_processing_principal.application_id
    lawPluginAppSecret                          = azuread_application_password.log_processing_principal.value
    lawPluginTenantId                           = data.azuread_client_config.current.tenant_id
    lawPluginDataCollectionEndpointURI          = azurerm_monitor_data_collection_endpoint.avs_log_processing_dce.logs_ingestion_endpoint
    lawPluginDcrImmutableId                     = azurerm_monitor_data_collection_rule.avs_log_processing_dcr.immutable_id
    lawPluginDcrStreamName                      = var.custom_table_name
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
  for_each            = { for vm in var.logstash_vms : vm.vm_name => vm_name }
  name                = "${each.value.vm_name}-nic-1"
  location            = azurerm_resource_group.avs_log_processing.location
  resource_group_name = azurerm_resource_group.avs_log_processing.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.logstash_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "logstash_vm" {
  for_each = { for vm in var.logstash_vms : vm.vm_name => vm_name }

  name                            = each.value.vm_name
  resource_group_name             = azurerm_resource_group.avs_log_processing.name
  location                        = azurerm_resource_group.avs_log_processing.location
  size                            = each.value.vm_sku #"Standard_E2as_v5"
  admin_username                  = "azureuser"
  admin_password                  = random_password.admin_password.result
  disable_password_authentication = false
  custom_data                     = data.template_cloudinit_config.config.rendered

  network_interface_ids = [
    azurerm_network_interface.logstash_nic[each.value.vm_name].id,
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
  for_each     = { for vm in var.logstash_vms : vm.vm_name => vm_name }
  name         = "${each.value.vm_name}-azureuser-password"
  value        = random_password.admin_password.result
  key_vault_id = azurerm_key_vault.infra_vault.id

  depends_on = [
    azurerm_key_vault_access_policy.deployment_user_access
  ]
}

