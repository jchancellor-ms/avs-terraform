
resource "azurerm_netapp_account" "example" {
  name                = "example-netappaccount"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_netapp_pool" "example" {
  name                = "example-netapppool"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  account_name        = azurerm_netapp_account.example.name
  service_level       = "Premium"
  size_in_tb          = 4
}

resource "azurerm_netapp_volume" "example" {
  lifecycle {
    prevent_destroy = true
  }

  name                       = "example-netappvolume"
  location                   = azurerm_resource_group.example.location
  resource_group_name        = azurerm_resource_group.example.name
  account_name               = azurerm_netapp_account.example.name
  pool_name                  = azurerm_netapp_pool.example.name
  volume_path                = "my-unique-file-path"
  service_level              = "Premium"
  subnet_id                  = azurerm_subnet.example.id
  network_features           = "Basic"
  protocols                  = ["NFSv4.1"]
  security_style             = "Unix"
  storage_quota_in_gb        = 100
  snapshot_directory_visible = false

  # When creating volume from a snapshot
  create_from_snapshot_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/group1/providers/Microsoft.NetApp/netAppAccounts/account1/capacityPools/pool1/volumes/volume1/snapshots/snapshot1"

  # Following section is only required if deploying a data protection volume (secondary)
  # to enable Cross-Region Replication feature
  data_protection_replication {
    endpoint_type             = "dst"
    remote_volume_location    = azurerm_resource_group.example.location
    remote_volume_resource_id = azurerm_netapp_volume.example.id
    replication_frequency     = "10minutes"
  }

  # Enabling Snapshot Policy for the volume
  # Note: this cannot be used in conjunction with data_protection_replication when endpoint_type is dst
  data_protection_snapshot_policy {
    snapshot_policy_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/group1/providers/Microsoft.NetApp/netAppAccounts/account1/snapshotPolicies/snapshotpolicy1"
  }
}

resource "azapi_update_resource" "netapp_datastore" {
  type        = "Microsoft.AVS/privateClouds@2021-12-01"
  resource_id = azurerm_vmware_private_cloud.privatecloud.id

  body = jsonencode({
    properties = {
      netAppVolume = azurerm_netapp_volume.example.id
    }
  })

  depends_on = [
    azurerm_vmware_private_cloud.privatecloud,
    azurerm_netapp_volume.example
  ]
}