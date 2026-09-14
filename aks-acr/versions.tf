terraform {
  required_version = ">= 1.7.0, < 2.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-axion-dev"
    storage_account_name = "stgaxiondev"
    container_name       = "app-data"
    key                  = "aks-dev.tfstate"
    use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {}
}