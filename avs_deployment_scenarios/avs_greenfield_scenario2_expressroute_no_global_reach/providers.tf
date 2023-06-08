terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.00"
    }
    azapi = {
      source = "azure/azapi"
    }
  }


  backend "azurerm" {
    resource_group_name  = "terraformtesting"
    storage_account_name = "jchancellortfstate"
    container_name       = "greenfield"
    key                  = "test-scenario2.tfstate"
    use_azuread_auth     = true
    subscription_id      = "1caa5ab4-523f-4851-952b-1b689c48fae9"
    tenant_id            = "8cb3390f-7308-4b0a-a113-432138b927aa"
  }
}

provider "azapi" {
}

provider "azuread" {
}

provider "azurerm" {
  features {}
}