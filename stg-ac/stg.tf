terraform {
	required_version = ">= 1.7.0, < 2.0.0"

	required_providers {
		azurerm = {
			source  = "hashicorp/azurerm"
			version = "~> 4.0"
		}
	}
}

provider "azurerm" {
	features {}
}

variable "resource_group_name" {
	description = "Name of the Azure resource group for the storage account."
	type        = string
	default     = "rg-axion-dev"
}

variable "location" {
	description = "Azure region for the resource group and storage account."
	type        = string
	default     = "centralindia"
}

variable "name_prefix" {
	description = "Lowercase prefix used to build the globally unique storage account name."
	type        = string
	default     = "axion"
}

variable "environment" {
	description = "Environment suffix used in the storage account name."
	type        = string
	default     = "dev"
}

resource "azurerm_resource_group" "this" {
	name     = var.resource_group_name
	location = var.location

	tags = {
		environment = var.environment
		managed_by  = "terraform"
	}
}

locals {
	storage_account_name = substr("stg${replace(var.name_prefix, "-", "")}${replace(var.environment, "-", "")}", 0, 24)
}

resource "azurerm_storage_account" "this" {
	name                            = local.storage_account_name
	resource_group_name             = azurerm_resource_group.this.name
	location                        = azurerm_resource_group.this.location
	account_kind                    = "StorageV2"
	account_tier                    = "Standard"
	account_replication_type        = "LRS"
	min_tls_version                 = "TLS1_2"
	https_traffic_only_enabled      = true
	public_network_access_enabled   = true
	allow_nested_items_to_be_public = false
	shared_access_key_enabled       = true

	tags = {
		environment = var.environment
		managed_by  = "terraform"
	}
}

resource "azurerm_storage_container" "this" {
	name                  = "app-data"
	storage_account_id    = azurerm_storage_account.this.id
	container_access_type = "private"
}
