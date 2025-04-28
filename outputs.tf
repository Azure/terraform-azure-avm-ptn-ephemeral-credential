output "password_bcrypt_hash" {
  description = "(String, Sensitive) A bcrypt hash of the generated random string. NOTE: If the generated random string is greater than 72 bytes in length, `bcrypt_hash` will contain a hash of the first 72 bytes."
  ephemeral   = true
  value       = try(ephemeral.random_password.this[0].password_bcrypt_hash, null)
}

output "password_key_vault_secret" {
  description = "Key Vault Secret resource that stores generated password."
  value       = try(azurerm_key_vault_secret.password[0], null)
}

output "password_result" {
  description = "(String, Sensitive) The generated random string."
  ephemeral   = true
  value       = try(ephemeral.random_password.this[0].result, null)
}

output "rotation_rfc3339" {
  description = "(String) Configure the rotation timestamp with an [RFC3339](https://datatracker.ietf.org/doc/html/rfc3339#section-5.8) format of the offset timestamp. When the current time has passed the rotation timestamp, the resource will trigger recreation. At least one of the 'rotation_' arguments must be configured."
  value       = try(time_rotating.this[0].rotation_rfc3339, null)
}

output "time_rotating_id" {
  description = "(String) RFC3339 format of the `time_rotating`'s timestamp, e.g. `2020-02-12T06:36:13Z`. When the rotation occurs, this value will be updated to the new timestamp. This is useful for tracking when the resource was last rotated."
  value       = try(time_rotating.this[0].id, null)
}

output "tls_private_key_key_openssh" {
  description = "(String, Sensitive) Private key data in [OpenSSH PEM (RFC 4716)](https://datatracker.ietf.org/doc/html/rfc4716) format."
  ephemeral   = true
  value       = try(ephemeral.tls_private_key.this[0].private_key_openssh, null)
}

output "tls_private_key_pem" {
  description = "(String, Sensitive) Private key data in [PEM (RFC 1421)](https://datatracker.ietf.org/doc/html/rfc1421) format."
  ephemeral   = true
  value       = try(ephemeral.tls_private_key.this[0].private_key_pem, null)
}

output "tls_private_key_pem_pkcs8" {
  description = "(String, Sensitive) Private key data in [PKCS#8 PEM (RFC 5208)](https://datatracker.ietf.org/doc/html/rfc5208) format."
  ephemeral   = true
  value       = try(ephemeral.tls_private_key.this[0].private_key_pem_pkcs8, null)
}

output "tls_private_key_public_key_fingerprint_md5" {
  description = "(String) The fingerprint of the public key data in OpenSSH MD5 hash format, e.g. `aa:bb:cc:...`. Only available if the selected private key format is compatible, similarly to `public_key_openssh` and the [ECDSA P224 limitations](../../docs#limitations)."
  ephemeral   = true
  value       = try(ephemeral.tls_private_key.this[0].public_key_fingerprint_md5, null)
}

output "tls_private_key_public_key_fingerprint_sha256" {
  description = "(String) The fingerprint of the public key data in OpenSSH SHA256 hash format, e.g. `SHA256:...`. Only available if the selected private key format is compatible, similarly to `public_key_openssh` and the [ECDSA P224 limitations](../../docs#limitations)."
  ephemeral   = true
  value       = try(ephemeral.tls_private_key.this[0].public_key_fingerprint_sha256, null)
}

output "tls_private_key_public_key_openssh" {
  description = "(String) The public key data in [\"Authorized Keys\"](https://www.ssh.com/academy/ssh/authorized_keys/openssh#format-of-the-authorized-keys-file) format. This is not populated for `ECDSA` with curve `P224`, as it is [not supported](../../docs#limitations). **NOTE**: the [underlying](https://pkg.go.dev/encoding/pem#Encode) [libraries](https://pkg.go.dev/golang.org/x/crypto/ssh#MarshalAuthorizedKey) that generate this value append a `\n` at the end of the PEM. In case this disrupts your use case, we recommend using [`trimspace()`](https://www.terraform.io/language/functions/trimspace)."
  ephemeral   = true
  value       = try(ephemeral.tls_private_key.this[0].public_key_openssh, null)
}

output "tls_private_key_public_key_pem" {
  description = "(String) Public key data in [PEM (RFC 1421)](https://datatracker.ietf.org/doc/html/rfc1421) format. **NOTE**: the [underlying](https://pkg.go.dev/encoding/pem#Encode) [libraries](https://pkg.go.dev/golang.org/x/crypto/ssh#MarshalAuthorizedKey) that generate this value append a `\n` at the end of the PEM. In case this disrupts your use case, we recommend using [`trimspace()`](https://www.terraform.io/language/functions/trimspace)."
  ephemeral   = true
  value       = try(ephemeral.tls_private_key.this[0].public_key_pem, null)
}

output "value_wo_version" {
  description = "(Number) Unix format of the `time_rotating`'s timestamp, e.g. `1581490573`. When the rotation occurs, this value will be updated to the new timestamp. This is useful for tracking when the resource was last rotated. You're encouraged to use this output as `value_wo_version` when you want to assign the ephemeral credential to write-only value."
  value       = try(time_rotating.this[0].unix, null)
}
