resource "azurerm_firewall_policy_rule_collection_group" "outbound_internet_test_group" {
  count              = var.has_firewall_policy ? 1 : 0
  name               = "outbound_internet_test_group"
  firewall_policy_id = var.firewall_policy_id
  priority           = 1000

  network_rule_collection {
    name     = "network_rule_collection1"
    priority = 1000
    action   = "Allow"
    rule {
      name                  = "outbound_internet"
      protocols             = ["TCP", "UDP"]
      source_addresses      = var.avs_ip_ranges
      destination_addresses = ["*"]
      destination_ports     = ["80", "443", "53"]
    }
  }
}

resource "azurerm_firewall_network_rule_collection" "outbound_internet_test_collection" {
  count               = var.has_firewall_policy ? 0 : 1
  name                = "outbound_internet_test_collection"
  azure_firewall_name = var.azure_firewall_name
  resource_group_name = var.azure_firewall_rg_name
  priority            = 1000
  action              = "Allow"

  rule {
    name                  = "outbound_internet"
    source_addresses      = var.avs_ip_ranges
    destination_ports     = ["80", "443", "53"]
    destination_addresses = ["*"]
    protocols             = ["TCP", "UDP"]
  }
}

