data "azurerm_client_config" "current" {}

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

module "retrievable_key" {
  source = "../../"

  enable_telemetry = false
  private_key = {
    algorithm = "RSA"
    rsa_bits  = 2048
  }
  time_rotating = {
    rotation_months = 1
  }
}

locals {
  user_name = "testadmin"
}

resource "azapi_resource" "resource_group" {
  location = "westus"
  name     = "ephemeral-credential-${random_string.id.result}"
  type     = "Microsoft.Resources/resourceGroups@2020-06-01"
}

resource "azapi_resource" "virtual_network" {
  location  = azapi_resource.resource_group.location
  name      = "ephemeral-credential-${random_string.id.result}"
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
  name      = "ephemeral-credential-subnet${random_string.id.result}"
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
  name      = "ephemeral-credential-nic${random_string.id.result}"
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

resource "azapi_resource" "virtual_machine" {
  location  = azapi_resource.resource_group.location
  name      = "ephemeral-credential-vm${random_string.id.result}"
  parent_id = azapi_resource.resource_group.id
  type      = "Microsoft.Compute/virtualMachines@2023-03-01"
  body = {
    properties = {
      hardwareProfile = {
        vmSize = "Standard_F2"
      }
      networkProfile = {
        networkInterfaces = [
          {
            id = azapi_resource.network_interface.id
            properties = {
              primary = false
            }
          },
        ]
      }
      osProfile = {
        adminUsername = local.user_name
        computerName  = "hostname230630032848831819"
        linuxConfiguration = {
          disablePasswordAuthentication = true
        }
      }
      storageProfile = {
        imageReference = {
          offer     = "UbuntuServer"
          publisher = "Canonical"
          sku       = "16.04-LTS"
          version   = "latest"
        }
        osDisk = {
          caching                 = "ReadWrite"
          createOption            = "FromImage"
          name                    = "myosdisk1"
          writeAcceleratorEnabled = false
        }
      }
    }
  }
  response_export_values    = ["*"]
  schema_validation_enabled = false
  sensitive_body = {
    properties = {
      osProfile = {
        linuxConfiguration = {
          ssh = {
            publicKeys = [
              {
                # Though the public key is not sensitive,but the whole private key is ephemeral resource so every time we read it's value, it refreshes, so we have to set it as sensitive body along with a value_wo_version to indicate when should this resource update the key.
                keyData = module.retrievable_key.public_key_openssh
                path    = "/home/${local.user_name}/.ssh/authorized_keys"
              }
            ]
          }
        }
      }
    }
  }
  sensitive_body_version = {
    "properties.osProfile.linuxConfiguration.ssh" : module.retrievable_key.value_wo_version
  }
}
