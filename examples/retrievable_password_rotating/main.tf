data "azapi_client_config" "current" {}

resource "azapi_resource" "resource_group" {
  location = "westus"
  name     = "ephemeral-credential-${random_string.id.result}"
  type     = "Microsoft.Resources/resourceGroups@2020-06-01"
}

resource "random_string" "id" {
  length  = 5
  special = false
  upper   = false
}

resource "azurerm_key_vault" "example" {
  location                   = azapi_resource.resource_group.location
  name                       = "ephemeralavm${random_string.id.result}"
  resource_group_name        = azapi_resource.resource_group.name
  sku_name                   = "premium"
  tenant_id                  = data.azapi_client_config.current.tenant_id
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
    object_id = data.azapi_client_config.current.object_id
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
    tenant_id = data.azapi_client_config.current.tenant_id
  }
}

module "retrievable_password" {
  source = "../../"

  enable_telemetry = false
  password = {
    length      = 20
    special     = true
    upper       = true
    lower       = true
    numeric     = true
    min_lower   = 2
    min_upper   = 2
    min_numeric = 2
    min_special = 2
  }
  retrievable_secret = {
    key_vault_id = azurerm_key_vault.example.id
    name         = "ephemeral-vm-password-${random_string.id.result}"
  }
  time_rotating = {
    rotation_months = 1
  }
}

resource "azapi_resource" "virtual_network" {
  location  = azapi_resource.resource_group.location
  name      = "ephemeral-vnet-${random_string.id.result}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/virtualNetworks@2022-07-01"
  body = {
    properties = {
      addressSpace = {
        addressPrefixes = [
          "10.0.0.0/16",
        ]
      }
      dhcpOptions = {
        dnsServers = [
        ]
      }
      subnets = [
      ]
    }
  }
  response_export_values    = ["*"]
  schema_validation_enabled = false

  lifecycle {
    ignore_changes = [body.properties.subnets]
  }
}

resource "azapi_resource" "subnet" {
  name      = "ephemeral-subnet-${random_string.id.result}"
  parent_id = azapi_resource.virtual_network.id
  type      = "Microsoft.Network/virtualNetworks/subnets@2022-07-01"
  body = {
    properties = {
      addressPrefix = "10.0.2.0/24"
      delegations = [
      ]
      privateEndpointNetworkPolicies    = "Enabled"
      privateLinkServiceNetworkPolicies = "Enabled"
      serviceEndpointPolicies = [
      ]
      serviceEndpoints = [
      ]
    }
  }
  response_export_values    = ["*"]
  schema_validation_enabled = false
}


resource "azapi_resource" "network_interface" {
  location  = azapi_resource.resource_group.location
  name      = "nic"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Network/networkInterfaces@2022-07-01"
  body = {
    properties = {
      enableAcceleratedNetworking = false
      enableIPForwarding          = false
      ipConfigurations = [
        {
          name = "testconfiguration1"
          properties = {
            primary                   = true
            privateIPAddressVersion   = "IPv4"
            privateIPAllocationMethod = "Dynamic"
            subnet = {
              id = azapi_resource.subnet.id
            }
          }
        },
      ]
    }
  }
  response_export_values    = ["*"]
  schema_validation_enabled = false
}

resource "azapi_resource" "windows_virtual_machine" {
  location  = azapi_resource.resource_group.location
  name      = "ephemeral-vm-${random_string.id.result}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Compute/virtualMachines@2024-07-01"
  body = {
    properties = {
      hardwareProfile = {
        vmSize = "Standard_F2"
      }
      networkProfile = {
        networkInterfaces = [{
          id = azapi_resource.network_interface.id
          properties = {
            primary = true
          }
        }]
      }
      osProfile = {
        adminUsername = "adminuser"
        computerName  = "example-machine"
        windowsConfiguration = {
          enableAutomaticUpdates = true
        }
      }
      storageProfile = {
        dataDisks = []
        imageReference = {
          offer     = "WindowsServer"
          publisher = "MicrosoftWindowsServer"
          sku       = "2016-Datacenter"
          version   = "latest"
        }
        osDisk = {
          caching                 = "ReadWrite"
          createOption            = "FromImage"
          name                    = "myosdisk1"
          osType                  = "Windows"
          writeAcceleratorEnabled = false
        }
      }
    }
  }
  sensitive_body = {
    properties = {
      osProfile = {
        adminPassword = module.retrievable_password.password_result
      }
    }
  }
  sensitive_body_version = {
    "properties.osProfile.adminPassword" : module.retrievable_password.value_wo_version
  }
}
