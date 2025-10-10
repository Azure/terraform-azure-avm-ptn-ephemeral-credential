output "password_result" {
  description = "(String, Ephemeral) The generated random string. This password is ephemeral and will be discarded after the Terraform apply finishes if `var.key_vault_password_secret` is `null`, otherwise this value will be the password from the Key Vault secret. This output is available even if `var.password` is `null`, because Terraform DO NOT support `null` as ephemeral output. You MUST NOT use it in that case."
  ephemeral   = true
  value       = var.password != null && var.retrievable_secret != null ? ephemeral.azurerm_key_vault_secret.retrievable_secret[0].value : ephemeral.random_password.this.result
}

output "private_key_algorithm" {
  description = "(String) The name of the algorithm used by the given private key. Possible values are: `RSA`, `ECDSA`, `ED25519`. This output is available even if `var.private_key` is `null`, because Terraform DO NOT support `null` as ephemeral output. You MUST NOT use it in that case."
  ephemeral   = true
  value       = var.private_key != null ? ephemeral.ephemeraltls_public_key.this[0].algorithm : ephemeral.tls_private_key.dummy.algorithm
}

output "public_key_fingerprint_md5" {
  description = "(String) The fingerprint of the public key data in OpenSSH MD5 hash format, e.g. `aa:bb:cc:...`. Only available if the selected private key format is compatible, as per the rules for `public_key_openssh` and [ECDSA P224 limitations](../../docs#limitations). This output is available even if `var.private_key` is `null`, because Terraform DO NOT support `null` as ephemeral output. You MUST NOT use it in that case."
  ephemeral   = true
  value       = var.private_key != null ? ephemeral.ephemeraltls_public_key.this[0].public_key_fingerprint_md5 : ephemeral.tls_private_key.dummy.public_key_fingerprint_md5
}

output "public_key_fingerprint_sha256" {
  description = "(String) The fingerprint of the public key data in OpenSSH SHA256 hash format, e.g. `SHA256:...`. Only available if the selected private key format is compatible, as per the rules for `public_key_openssh` and [ECDSA P224 limitations](../../docs#limitations). This output is available even if `var.private_key` is `null`, because Terraform DO NOT support `null` as ephemeral output. You MUST NOT use it in that case."
  ephemeral   = true
  value       = var.private_key != null ? ephemeral.ephemeraltls_public_key.this[0].public_key_fingerprint_sha256 : ephemeral.tls_private_key.dummy.public_key_fingerprint_sha256
}

output "public_key_openssh" {
  description = "(String) The public key, in  [OpenSSH PEM (RFC 4716)](https://datatracker.ietf.org/doc/html/rfc4716) format. This is also known as ['Authorized Keys'](https://www.ssh.com/academy/ssh/authorized_keys/openssh#format-of-the-authorized-keys-file) format. This is not populated for `ECDSA` with curve `P224`, as it is [not supported](../../docs#limitations). **NOTE**: the [underlying](https://pkg.go.dev/encoding/pem#Encode) [libraries](https://pkg.go.dev/golang.org/x/crypto/ssh#MarshalAuthorizedKey) that generate this value append a `\n` at the end of the PEM. In case this disrupts your use case, we recommend using [`trimspace()`](https://www.terraform.io/language/functions/trimspace). This output is available even if `var.private_key` is `null`, because Terraform DO NOT support `null` as ephemeral output. You MUST NOT use it in that case."
  ephemeral   = true
  value       = var.private_key != null ? ephemeral.ephemeraltls_public_key.this[0].public_key_openssh : ephemeral.tls_private_key.dummy.public_key_openssh
}

output "public_key_pem" {
  description = "(String) The public key, in [PEM (RFC 1421)](https://datatracker.ietf.org/doc/html/rfc1421) format. **NOTE**: the [underlying](https://pkg.go.dev/encoding/pem#Encode) [libraries](https://pkg.go.dev/golang.org/x/crypto/ssh#MarshalAuthorizedKey) that generate this value append a `\n` at the end of the PEM. In case this disrupts your use case, we recommend using [`trimspace()`](https://www.terraform.io/language/functions/trimspace). This output is available even if `var.private_key` is `null`, because Terraform DO NOT support `null` as ephemeral output. You MUST NOT use it in that case."
  ephemeral   = true
  value       = var.private_key != null ? ephemeral.ephemeraltls_public_key.this[0].public_key_pem : ephemeral.tls_private_key.dummy.public_key_pem
}

output "retrievable_secret_id" {
  description = "The ID of the retrievable Key Vault Secret"
  value       = try(azurerm_key_vault_secret.retrievable_secret[0].id, null)
}

output "retrievable_secret_name" {
  description = "The name of the retrievable Key Vault Secret"
  value       = try(azurerm_key_vault_secret.retrievable_secret[0].name, null)
}

output "value_wo_version" {
  description = "(Number) Unix format of the `time_rotating`'s timestamp, e.g. `1581490573`. When the rotation occurs, this value will be updated to the new timestamp. This is useful for tracking when the resource was last rotated. You're encouraged to use this output as `value_wo_version` when you want to assign the ephemeral credential to write-only value."
  value       = try(time_rotating.rotating[0].unix, time_static.now[0].unix)
}
