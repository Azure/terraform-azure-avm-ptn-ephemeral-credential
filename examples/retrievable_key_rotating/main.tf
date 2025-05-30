terraform {
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.12.1"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_deleted_keys_on_destroy = true
      recover_soft_deleted_keys          = true
    }
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "example" {
  location = "West Europe"
  name     = "zjhe-keyvault${random_string.id.result}"
}

resource "random_string" "id" {
  length  = 5
  special = false
  upper   = false
}

resource "azurerm_key_vault" "example" {
  location                   = azurerm_resource_group.example.location
  name                       = "ephemeralavm${random_string.id.result}"
  resource_group_name        = azurerm_resource_group.example.name
  sku_name                   = "premium"
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days = 7

  access_policy {
    key_permissions = [
      "Create",
      "Delete",
      "Get",
      "Purge",
      "Recover",
      "Update",
      "GetRotationPolicy",
      "SetRotationPolicy",
      "List",
    ]
    object_id = data.azurerm_client_config.current.object_id
    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Recover",
      "Backup",
      "Restore",
      "Purge",
    ]
    tenant_id = data.azurerm_client_config.current.tenant_id
  }
}

module "non_retrievable_password" {
  source = "../../"

  enable_telemetry = false
  key_vault_key = {
    name         = "generated-key"
    key_vault_id = azurerm_key_vault.example.id
    key_type     = "RSA"
    key_size     = 4096
    key_opts = [
      "decrypt",
      "encrypt",
      "sign",
      "unwrapKey",
      "verify",
      "wrapKey",
    ]

    rotation_policy = {
      automatic = {
        time_before_expiry = "P30D"

      }
      expire_after         = "P90D"
      notify_before_expiry = "P29D"
    }
  }
}

resource "azurerm_key_vault_secret" "non_retrievable_password" {
  key_vault_id = azurerm_key_vault.example.id
  name         = "non-retrievable-password"
  value        = module.non_retrievable_password.retrievable_public_key_openssh
}
