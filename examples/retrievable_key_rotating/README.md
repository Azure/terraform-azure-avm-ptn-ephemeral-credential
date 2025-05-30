<!-- BEGIN_TF_DOCS -->
# Non-retrievable password without rotation example

This deploys a retrievable ephemeral private key with TTL. The key is stored in Azure Key Vault.

```hcl
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
```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_random"></a> [random](#requirement\_random) (3.7.2)

- <a name="requirement_time"></a> [time](#requirement\_time) (0.12.1)

## Resources

The following resources are used by this module:

- [azurerm_key_vault.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) (resource)
- [azurerm_key_vault_secret.non_retrievable_password](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) (resource)
- [azurerm_resource_group.example](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [random_string.id](https://registry.terraform.io/providers/hashicorp/random/3.7.2/docs/resources/string) (resource)
- [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) (data source)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_enable_telemetry"></a> [enable\_telemetry](#input\_enable\_telemetry)

Description: This variable controls whether or not telemetry is enabled for the module.  
For more information see <https://aka.ms/avm/telemetryinfo>.  
If it is set to false, then no telemetry will be collected.

Type: `bool`

Default: `true`

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_non_retrievable_password"></a> [non\_retrievable\_password](#module\_non\_retrievable\_password)

Source: ../../

Version:

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->