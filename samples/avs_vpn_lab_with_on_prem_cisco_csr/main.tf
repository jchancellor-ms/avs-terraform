###### Deploy the AVS side hub ###############
module "deploy_greenfield_new_vpn_hub_no_firewall" {
  source = "../../official/Enterprise-Scale-for-AVS/terraform/scenarios/avs_greenfield_new_vpn_hub"

  prefix = "jcopnva1"
  region = "Southeast Asia"

  vnet_address_space = ["10.40.0.0/16"]
  subnets = [
    {
      name           = "GatewaySubnet",
      address_prefix = ["10.40.1.0/24"]
    },
    {
      name           = "RouteServerSubnet",
      address_prefix = ["10.40.2.0/24"]
    },
    {
      name           = "AzureBastionSubnet",
      address_prefix = ["10.40.3.0/24"]
    },
    {
      name           = "JumpBoxSubnet"
      address_prefix = ["10.40.4.0/24"]
    },
    {
      name           = "AzureFirewallSubnet"
      address_prefix = ["10.40.5.0/24"]
    }
  ]

  expressroute_gateway_sku = "Standard"
  sddc_sku                 = "av36"
  management_cluster_size  = 3
  avs_network_cidr         = "10.2.0.0/20"
  vpn_gateway_sku          = "VpnGw2"
  asn                      = 65515
  firewall_sku_tier        = "Standard"
  email_addresses          = ["jchancellor@microsoft.com"]


  tags = {
    environment = "Dev"
    CreatedBy   = "Terraform"
  }
}


######## Create a pre-shared key for the VPN ######
resource "random_password" "shared_key" {
  length  = 20
  special = false
  upper   = true
  lower   = true
}

resource "azurerm_key_vault_secret" "vpn_shared_key" {
  name         = "on-prem-to-avs-vpn-shared-key"
  value        = random_password.shared_key.result
  key_vault_id = module.deploy_on_prem_nva_vpn.key_vault_id
  depends_on   = [module.deploy_on_prem_nva_vpn.key_vault_id]
}



#Deploy an dummy on-prem
######## Deploy the CSR and on-prem jump #########
module "deploy_on_prem_nva_vpn" {
  source = "../../avs-terraform/avs_deployment_scenarios/avs_test_vpn_nva_one_node"

  prefix = "jcopnva1"
  region = "Southeast Asia"

  vnet_address_space = ["10.50.0.0/16"]
  subnets = [
    {
      name           = "AzureBastionSubnet",
      address_prefix = ["10.50.1.0/24"]
    },
    {
      name           = "JumpBoxSubnet"
      address_prefix = ["10.50.2.0/24"]
    },
    {
      name           = "CSRSubnet"
      address_prefix = ["10.50.0.0/24"]
    }
  ]

  csr_bgp_ip          = "192.168.255.1"
  csr_tunnel_cidr     = "172.30.0.0/28"
  csr_subnet_name     = "CSRSubnet"
  remote_bgp_peer_ips = module.deploy_greenfield_new_vpn_hub_no_firewall.vpn_gateway_bgp_peering_addresses
  pre_shared_key      = random_password.shared_key.result
  asn                 = 64100
  jumpbox_sku         = "Standard_D2as_v4"
  admin_username      = "azureuser"
  remote_gw_pubip0    = module.deploy_greenfield_new_vpn_hub_no_firewall.vpn_gateway_pip_1
  remote_gw_pubip1    = module.deploy_greenfield_new_vpn_hub_no_firewall.vpn_gateway_pip_2
  tags = {
    environment = "Dev"
    CreatedBy   = "Terraform"
  }
}


module "create_vpn_connections" {
  source = "../../avs-terraform/modules/avs_vpn_create_local_gateways_and_connections_active_active_w_bgp"

  rg_name                    = module.deploy_greenfield_new_vpn_hub_no_firewall.network_resource_group_name
  rg_location                = module.deploy_greenfield_new_vpn_hub_no_firewall.network_resource_group_location
  virtual_network_gateway_id = module.deploy_greenfield_new_vpn_hub_no_firewall.vpn_gateway_id
  #remote configurations
  remote_asn                     = module.deploy_on_prem_nva_vpn.asn
  local_gateway_bgp_ip           = module.deploy_on_prem_nva_vpn.csr_bgp_ip
  local_gateway_name_0           = "on-prem-csr-peer-0"
  local_gateway_name_1           = "on-prem-csr-peer-1"
  vnet_gateway_connection_name_0 = "on-prem-csr-peer-0-connection"
  vnet_gateway_connection_name_1 = "on-prem-csr-peer-1-connection"
  remote_gateway_address_0       = module.deploy_on_prem_nva_vpn.csr_pip_0
  remote_gateway_address_1       = module.deploy_on_prem_nva_vpn.csr_pip_0
  bgp_peering_address_0          = module.deploy_on_prem_nva_vpn.bgp_peer_ip_0
  bgp_peering_address_1          = module.deploy_on_prem_nva_vpn.bgp_peer_ip_1
  shared_key                     = random_password.shared_key.result

  depends_on = [
    module.deploy_on_prem_nva_vpn,
    module.deploy_greenfield_new_vpn_hub_no_firewall
  ]

}

#create a test spoke for connectivity testing from Azure
module "create_test_spoke_with_jump" {
  source = "../../official/Enterprise-Scale-for-AVS/terraform/modules/avs_test_spoke_with_jump_vm"

  prefix                           = "jcopnva1"
  region                           = "Southeast Asia"
  jumpbox_sku                      = "Standard_D2as_v4"
  admin_username                   = "azureuser"
  hub_vnet_name                    = module.deploy_greenfield_new_vpn_hub_no_firewall.vnet_name
  hub_rg_name                      = module.deploy_greenfield_new_vpn_hub_no_firewall.network_resource_group_name
  jumpbox_spoke_vnet_address_space = ["10.60.0.0/16"]
  bastion_subnet_prefix            = "10.60.0.0/24"
  jumpbox_subnet_prefix            = "10.60.1.0/24"
  tags = {
    environment = "Dev"
    CreatedBy   = "Terraform"
  }
}
