terraform {
  required_version = "~> 1.11"

  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.4"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "prefix" {
  type    = string
  default = "avmec"
}

module "regions" {
  source  = "Azure/avm-utl-regions/azurerm"
  version = "0.12.0"

  is_recommended = true
}

resource "random_integer" "region_index" {
  max = length(module.regions.regions) - 1
  min = 0
}

resource "random_string" "suffix" {
  length  = 8
  upper   = false
  special = false
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "this" {
  name     = "rg-${var.prefix}-${random_string.suffix.result}"
  location = module.regions.regions[random_integer.region_index.result].name
}

resource "azurerm_key_vault" "this" {
  name                       = "kv${var.prefix}${random_string.suffix.result}"
  location                   = azurerm_resource_group.this.location
  resource_group_name        = azurerm_resource_group.this.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  enable_rbac_authorization  = false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get", "List", "Set", "Delete", "Recover", "Backup", "Restore", "Purge",
    ]
  }
}

output "key_vault_id" {
  value = azurerm_key_vault.this.id
}

output "location" {
  value = azurerm_resource_group.this.location
}

output "secret_name" {
  value = "ephemeral-test-password-${random_string.suffix.result}"
}
