#firewall errors if not installed in the same resource group as the vnet with the firewall subnet
#passing the resource group details in as a variable and creating a manual depends on reference

resource "azurerm_log_analytics_workspace" "simple" {
  name                = var.log_analytics_name
  location            = var.rg_location
  resource_group_name = var.rg_name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = var.tags
}

resource "azurerm_public_ip" "firewall_pip" {
  name                = var.firewall_pip_name
  location            = var.rg_location
  resource_group_name = var.rg_name

  allocation_method = "Static"
  sku               = "Standard"
  tags              = var.tags
}

resource "azurerm_firewall" "firewall" {
  name                = var.firewall_name
  location            = var.rg_location
  resource_group_name = var.rg_name
  sku_name            = "AZFW_VNet"
  sku_tier            = var.firewall_sku_tier
  private_ip_ranges   = ["IANAPrivateRanges", ]
  tags                = var.tags
  firewall_policy_id  = azurerm_firewall_policy.avs_base_policy.id

  ip_configuration {
    name                 = "firewall-ipconfiguration1"
    subnet_id            = var.firewall_subnet_id
    public_ip_address_id = azurerm_public_ip.firewall_pip.id
  }
}

resource "azurerm_firewall_policy" "avs_base_policy" {
  name                = var.firewall_policy_name
  resource_group_name = var.rg_name
  location            = var.rg_location
  dns {
    proxy_enabled = true
  }
}

#configure the firewall to send logs to a log analytics workspace
resource "azurerm_monitor_diagnostic_setting" "firewall_metrics" {
  name                           = "${var.firewall_name}-diagnostic-setting"
  target_resource_id             = azurerm_firewall.firewall.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.simple.id
  log_analytics_destination_type = "AzureDiagnostics"

  enabled_log {
    category = "AzureFirewallApplicationRule"

    retention_policy {
      enabled = false
    }
  }

  enabled_log {
    category = "AzureFirewallNetworkRule"

    retention_policy {
      enabled = false
    }
  }

  enabled_log {
    category = "AzureFirewallDnsProxy"

    retention_policy {
      enabled = false
    }
  }

  enabled_log {
    category = "AZFWNetworkRule"

    retention_policy {
      enabled = false
    }
  }

  enabled_log {
    category = "AZFWApplicationRule"

    retention_policy {
      enabled = false
    }
  }

  enabled_log {
    category = "AZFWNatRule"

    retention_policy {
      enabled = false
    }
  }

  enabled_log {
    category = "AZFWThreatIntel"

    retention_policy {
      enabled = false
    }
  }

  enabled_log {
    category = "AZFWIdpsSignature"

    retention_policy {
      enabled = false
    }
  }

  enabled_log {
    category = "AZFWDnsQuery"

    retention_policy {
      enabled = false
    }
  }

  enabled_log {
    category = "AZFWFqdnResolveFailure"

    retention_policy {
      enabled = false
    }
  }

  enabled_log {
    category = "AZFWApplicationRuleAggregation"

    retention_policy {
      enabled = false
    }
  }

  enabled_log {
    category = "AZFWNetworkRuleAggregation"

    retention_policy {
      enabled = false
    }
  }

  enabled_log {
    category = "AZFWNatRuleAggregation"

    retention_policy {
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

