locals {
  vnet_name          = "testLoggingVnet"
  vnet_address_space = ["10.200.0.0/16"]
  subnets = [
    {
      name           = "AzureBastionSubnet"
      address_prefix = ["10.200.0.0/24"]
    },
    {
      name           = "LogstashSubnet"
      address_prefix = ["10.200.1.0/24"]
    }
  ]
}

#create the resource group for all of the log processing items
resource "azurerm_resource_group" "avs_log_processing" {
  name     = var.rg_name
  location = var.rg_location
}

#create a virtual network for testing
module "test_virtual_network" {
  source = "../../modules/avs_vnet_variable_subnets"

  rg_name            = azurerm_resource_group.avs_log_processing.name
  rg_location        = azurerm_resource_group.avs_log_processing.location
  vnet_name          = local.vnet_name
  vnet_address_space = local.vnet_address_space
  subnets            = local.subnets
  tags               = var.tags
}


#create the event hub artifacts
module "create_event_hub_resources" {
  source = "../../modules/avs_event_hub_for_logs"

  rg_name                                     = azurerm_resource_group.avs_log_processing.name
  rg_location                                 = azurerm_resource_group.avs_log_processing.location
  eventhub_namespace_name                     = var.eventhub_namespace_name
  eventhub_capacity                           = var.eventhub_capacity
  eventhub_name                               = var.eventhub_name
  eventhub_partition_count                    = var.eventhub_partition_count
  eventhub_message_retention_days             = var.eventhub_message_retention_days
  diagnostic_eventhub_authorization_rule_name = var.diagnostic_eventhub_authorization_rule_name
  logstash_eventhub_authorization_rule_name   = var.logstash_eventhub_authorization_rule_name
  consumer_group_name                         = var.consumer_group_name
  plugin_storage_account_name                 = var.plugin_storage_account_name
  tags                                        = var.tags
}

#create a logging application and service principal
module "create_logging_service_principal" {
  source                                    = "../../modules/avs_log_filtering_accounts"
  avs_log_processing_service_principal_name = var.avs_log_processing_service_principal_name
}

#create the log analytics workspace, dCE and DCR resources
module "create_log_analytics_resources" {
  source = "../../modules/avs_log_analytics_w_custom_syslog"

  rg_name                            = azurerm_resource_group.avs_log_processing.name
  rg_location                        = azurerm_resource_group.avs_log_processing.location
  tags                               = var.tags
  log_analytics_name                 = var.log_analytics_name
  custom_table_name                  = var.custom_table_name
  data_collection_endpoint_name      = var.data_collection_endpoint_name
  data_collection_rule_name          = var.data_collection_rule_name
  log_processing_principal_object_id = module.create_logging_service_principal.logging_object_id
}

#create a keyvault and access policy
#deploy the key vault for the jump host
data "azuread_client_config" "current" {}

module "avs_keyvault_with_access_policy" {
  source = "../../modules/avs_key_vault"

  #values to create the keyvault
  rg_name                   = azurerm_resource_group.avs_log_processing.name
  rg_location               = azurerm_resource_group.avs_log_processing.location
  keyvault_name             = var.keyvault_name
  azure_ad_tenant_id        = data.azuread_client_config.current.tenant_id
  deployment_user_object_id = data.azuread_client_config.current.object_id
  tags                      = var.tags
}

#create the logstash vms and use cloud-init to install and configure logstash
module "avs_logstash_vms" {
  source   = "../../modules/avs_log_filtering_vm"
  for_each = { for vm in var.logstash_vms : vm.vm_name => vm }

  rg_name            = azurerm_resource_group.avs_log_processing.name
  rg_location        = azurerm_resource_group.avs_log_processing.location
  tags               = var.tags
  vm_name            = each.value.vm_name
  vm_sku             = each.value.vm_sku
  logstash_subnet_id = module.test_virtual_network.subnet_ids["LogstashSubnet"].id
  key_vault_id       = module.avs_keyvault_with_access_policy.keyvault_id

  logstash_values = {
    eventHubConnectionString                    = module.create_event_hub_resources.event_hub_connection_string
    eventHubConsumerGroupName                   = module.create_event_hub_resources.event_hub_consumer_group_name
    eventHubInputStorageAccountConnectionString = module.create_event_hub_resources.event_hub_storage_account_name
    lawPluginAppId                              = module.create_logging_service_principal.logging_application_id
    lawPluginAppSecret                          = module.create_logging_service_principal.logging_application_secret
    lawPluginTenantId                           = data.azuread_client_config.current.tenant_id
    lawPluginDataCollectionEndpointURI          = module.create_log_analytics_resources.logs_ingestion_endpoint
    lawPluginDcrImmutableId                     = module.create_log_analytics_resources.dcr_immutable_id
    lawPluginDcrStreamName                      = module.create_log_analytics_resources.dcr_stream_name
  }

  depends_on = [
    module.avs_keyvault_with_access_policy
  ]
}


#######################################################################################################################
# Configure a diagnostic setting on the private cloud to send the syslog data to the event hub
#######################################################################################################################

resource "azurerm_monitor_diagnostic_setting" "private_cloud_syslog" {
  name                           = var.diagnostics_setting_name
  target_resource_id             = var.private_cloud_resource_id
  eventhub_name                  = module.create_event_hub_resources.event_hub_name
  eventhub_authorization_rule_id = module.create_event_hub_resources.event_hub_authorization_rule_id

  enabled_log {
    category = "VMwareSyslog"

    retention_policy {
      enabled = false
    }
  }
}


/*
module "create_logging_solution" {
  source = "../../modules/avs_deploy_log_filtering_vm"

  rg_name                                     = "AvsLogFilterExample"
  rg_location                                 = "Canada Central"
  avs_log_processing_service_principal_name   = "AvsLogFilterSP"
  eventhub_namespace_name                     = "avslogfilterehnamespace"
  eventhub_capacity                           = 4
  eventhub_name                               = "avslogfiltereh"
  eventhub_partition_count                    = 2
  eventhub_message_retention_days             = 3
  diagnostic_eventhub_authorization_rule_name = "diagnosticSettingAuthRule"
  logstash_eventhub_authorization_rule_name   = "logstashAuthRule"
  consumer_group_name                         = "logstashConsumerGroup"
  plugin_storage_account_name                 = "avslogfilterstgacct"
  log_analytics_name                          = "avsLogAnalyticsWorkspace"
  custom_table_name                           = "Custom-AVSFilteredSyslog_CL"
  data_collection_endpoint_name               = "AvsLogFilterDataCollectionEndpoint"
  data_collection_rule_name                   = "AvsLogFilterDataCollectionRule"
  diagnostics_setting_name                    = "AVSEventHubLogAnalytics"
  private_cloud_resource_id                   = ""
  logstash_subnet_id                          = ""
  keyvault_name                               = "avslogkeyvault"

  tags = {
    environment = "Dev"
    CreatedBy   = "Terraform"
  }

  logstash_vms = [
    {
      vm_name = "logstashvm1",
      vm_sku  = "Standard_E2as_v5"
    },
    {
      vm_name = "logstashvm2",
      vm_sku  = "Standard_E2as_v5"
    },
  ]

}

*/