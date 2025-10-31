# terraform-azure-avm-ptn-ephemeral-credential

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

No Azure Key Vault nor HashiCorp Vault is required for **basic** usage, but they can be integrated for secure storage and retrieval of credentials.

## Supported Usage Scenarios

| Scenario                                    | How to Use                                                                                                                                                                     |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| 1. Windows VM, No Retrieval                 | Set `var.password`, leave `var.retrievable_secret = null`. Password is assigned and then thrown away. No one, including the creator, can later access it.               |
| 2. Linux VM, No Retrieval (Public Key)      | Set `var.private_key` to generate a temporary key pair. Use the public key to configure the VM. Private key is discarded. No one, including the creator, can later access it.  |
| 3. Password Stored in Azure Key Vault       | Set `var.password` and configure `var.retrievable_secret`. Password is assigned to VM and securely stored as a Key Vault Secret for later retrieval.                    |
| 4. Private Key Stored in Azure Key Vault    | Set `var.private_key` and configure `var.retrievable_secret`. Private key is securely stored as a Key Vault Secret for later retrieval.                                                                                |

## Credential Rotation Support

This module optionally supports a **rotation notification** system via `var.time_rotating`:

- Even without `var.time_rotating`, ephemeral credentials are **regenerated** each time Terraform refreshes them.
- Configuring `var.time_rotating` adds a monotonically increasing **version number** (`value_wo_version`) and a **next rotation timestamp** (`rotation_rfc3339`).
- This is helpful for downstream systems like Azure Key Vault or custom automation to know when to rotate or expire secrets.

> **Note:** `var.time_rotating` **cannot be used** when the `var.retrievable_secret` is set for private keys — rotation of private keys stored in Key Vault must be managed separately.
> **Note:** `var.time_rotating` **does not control** when the ephemeral password/private key is regenerated — it only creates a rotation metadata mechanism.
> **Note:** When credentials are stored in Key Vault via `var.retrievable_secret`, they are retrieved ephemerally during Terraform apply to compute outputs (like public keys from private keys) and assign to resources. The credentials are never persisted in Terraform state. After the apply completes, these ephemeral values are discarded. Credentials remain securely stored in Key Vault for later retrieval by authorized users or systems with appropriate Key Vault access permissions.

## Key Outputs

| Output                          | Description                                                                                                                    |
| ------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `password_result`               | The generated password (ephemeral, sensitive).                                                                                 |
| `private_key_algorithm`         | The name of the algorithm used by the private key (`RSA`, `ECDSA`, `ED25519`).                                                |
| `public_key_openssh`            | The public key in OpenSSH/Authorized Keys format.                                                                              |
| `public_key_pem`                | The public key in PEM format.                                                                                                  |
| `public_key_fingerprint_md5`    | The fingerprint of the public key in OpenSSH MD5 hash format.                                                                  |
| `public_key_fingerprint_sha256` | The fingerprint of the public key in OpenSSH SHA256 hash format.                                                               |
| `retrievable_secret_id`         | The ID of the Key Vault Secret (when `var.retrievable_secret` is set).                                                        |
| `retrievable_secret_name`       | The name of the Key Vault Secret (when `var.retrievable_secret` is set).                                                      |
| `value_wo_version`              | Unix timestamp that updates when rotation occurs - use this as version tracking for write-only credential assignments.         |

> **Important:** Due to Terraform's ephemeral output constraints, all credential-related outputs (`password_result`, `private_key_algorithm`, and all `public_key_*` outputs) are always available, even when the corresponding input variable (`var.password` or `var.private_key`) is `null`. However, **you MUST NOT use these outputs when the corresponding input is not set**. The module uses dummy ephemeral resources internally to satisfy Terraform's requirement that both branches of conditional expressions in ephemeral outputs must reference ephemeral resources. Always check your input configuration before using these outputs.

## Security Best Practices

- If you must retrieve credentials (e.g., via Key Vault), ensure tight access control.
- Remember that **ephemeral credentials refresh** every Terraform run, aligning with zero-trust principles.

> **Warning:** If `var.retrievable_secret` is not set, all generated credentials (passwords and private keys) will be discarded after VM creation and will not be retrievable later.

---

*Designed for security-first infrastructures in the Terraform era.*
