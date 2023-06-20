########################################################################################
#Deploy the Event hub items
########################################################################################
#Deploy the event hub namespace
resource "azurerm_eventhub_namespace" "avs_log_processing" {
  name                = var.eventhub_namespace_name
  location            = var.rg_location
  resource_group_name = var.rg_name
  sku                 = "Standard"
  capacity            = var.eventhub_capacity

  tags = var.tags
}

#deploy the event hub 
resource "azurerm_eventhub" "avs_log_processing" {
  name                = var.eventhub_name
  namespace_name      = azurerm_eventhub_namespace.avs_log_processing.name
  resource_group_name = var.rg_name
  partition_count     = var.eventhub_partition_count
  message_retention   = var.eventhub_message_retention_days
}

#deploy the authorization rule for the diagnostic setting
resource "azurerm_eventhub_namespace_authorization_rule" "avs_log_processing" {
  name                = var.diagnostic_eventhub_authorization_rule_name
  namespace_name      = azurerm_eventhub_namespace.avs_log_processing.name
  resource_group_name = var.rg_name

  listen = true
  send   = true
  manage = true
}

#deploy the authorization rule for the plugin
resource "azurerm_eventhub_authorization_rule" "avs_log_processing" {
  name                = var.logstash_eventhub_authorization_rule_name
  namespace_name      = azurerm_eventhub_namespace.avs_log_processing.name
  eventhub_name       = azurerm_eventhub.avs_log_processing.name
  resource_group_name = var.rg_name

  listen = true
  send   = true
  manage = true
}

#deploy an eventhub consumer group for use by the logstash plugin
resource "azurerm_eventhub_consumer_group" "avs_log_processing" {
  name                = var.consumer_group_name
  namespace_name      = azurerm_eventhub_namespace.avs_log_processing.name
  eventhub_name       = azurerm_eventhub.avs_log_processing.name
  resource_group_name = var.rg_name
}

#deploy a storage account for use by the eventhub plugin to maintain state
resource "azurerm_storage_account" "avs_log_processing" {
  name                     = var.plugin_storage_account_name
  resource_group_name      = var.rg_name
  location                 = var.rg_location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = var.tags
}