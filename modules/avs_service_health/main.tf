resource "azurerm_monitor_action_group" "avs_service_health" {
  name                = var.action_group_name
  resource_group_name = var.rg_name
  short_name          = var.action_group_shortname

  dynamic "email_receiver" {
    for_each = toset(var.email_addresses)
    content {
      name          = trimspace(split("@", email_receiver.key)[0])
      email_address = trimspace(email_receiver.key)
    }
  }
}

resource "azurerm_monitor_activity_log_alert" "avs_rg_service_health" {
  name                = var.service_health_alert_name
  resource_group_name = var.rg_name
  scopes              = [var.service_health_alert_scope_id]
  description         = "This alert monitors service health for the AVS SDDC resource group."

  criteria {
    category = "ServiceHealth"

    service_health {
      locations = ["Global"]
    }
  }



  action {
    action_group_id = azurerm_monitor_action_group.avs_service_health.id
  }
}