# terraform-azure-avm-utl-ephemeral-credential

## Introduction: Why "No-SSH"?

In modern cloud environments, especially when adopting DevOps best practices and immutable infrastructure models, it is increasingly recommended to avoid direct login access (SSH/RDP) to servers whenever possible. This approach, known as the **"No-SSH" style**, promotes:

- Stronger security by eliminating backdoor access.
- Clear separation between operational management and system state.
- Greater automation and resilience.

Inspired by the following ideas, this module helps implement "No-SSH" or minimal-access cloud infrastructures, especially when you still need to configure credentials during provisioning.

* [Immutable Infrastructure: No SSH](https://cloudcaptain.sh/blog/no-ssh)
* [To ssh, or not to ssh](https://steve-mushero.medium.com/to-ssh-or-not-to-ssh-c294b49298cd)
* [AWS re:Invent 2016: Life Without SSH: Immutable Infrastructure in Production (SAC318)](https://www.youtube.com/watch?v=fEuN5LkXfZk&ab_channel=AmazonWebServices)

## Why This Module Was Created

Traditional Terraform workflows either:

- Statically store credentials in state files (risky!), or
- Rely heavily on persistent SSH key management (contradicting No-SSH philosophy).

This module was created to solve:

- **Secure, ephemeral credential generation** at VM creation time.
- **No persistent secrets** unless explicitly required.
- **Support for rotation awareness** without breaking Terraform's refresh model.
- **Integration with Azure Key Vault** when retrieval is needed securely.

## Supported Usage Scenarios

| Scenario                                    | How to Use                                                                                                                                                       |
| ------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. Windows VM, No Retrieval                 | Set `var.password`, leave `var.key_vault_password_secret = null`. Password is assigned and then thrown away. No one, including the creator, can later access it. |
| 2. Linux VM, No Retrieval (Public Key)      | Set `var.private_key` to generate a temporary key pair. Use the public key to configure the VM. Private key is discarded.                                        |
| 3. Password Stored in Azure Key Vault       | Set `var.password` and configure `var.key_vault_password_secret`. Password is assigned to VM and securely stored as a Key Vault Secret for later retrieval.      |
| 4. Private Key Storage (Not Supported Here) | This module is **not intended** for private key storage. Please use `azurerm_key_vault_key` or another mechanism if needed.                                      |

## Credential Rotation Support

This module optionally supports a **rotation notification** system via `var.time_rotating`:

- Even without `var.time_rotating`, ephemeral credentials are **regenerated** each time Terraform refreshes them.
- Configuring `var.time_rotating` adds a monotonically increasing **version number** (`value_wo_version`) and a **next rotation timestamp** (`rotation_rfc3339`).
- This is helpful for downstream systems like Azure Key Vault or custom automation to know when to rotate or expire secrets.

> **Note:** `var.time_rotating` **does not control** when the ephemeral password/private key is regenerated — it only creates a rotation metadata mechanism.

## Key Outputs

| Output             | Description                                                    |
| ------------------ | -------------------------------------------------------------- |
| `value_wo`         | The generated password (sensitive).                            |
| `value_wo_version` | Updated when a rotation event happens (increase-only version). |
| `rotation_rfc3339` | RFC3339 timestamp of the next rotation.                        |

## Security Best Practices

- If you must retrieve credentials (e.g., via Key Vault), ensure tight access control.
- Remember that **ephemeral credentials refresh** every Terraform run, aligning with zero-trust principles.

> **Warning:** If `var.key_vault_password_secret` is not set, all generated credentials (passwords and private keys) will be discarded after VM creation and will not be retrievable later.

---

*Designed for security-first infrastructures in the Terraform era.*

