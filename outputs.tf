output "non_retrievable_private_key" {
  description = "non-retrievable ephemeral private key, this key would always be discarded after Terraform apply finished and there's no way to read the same key again. Each time you read this output would get a random new key so please use it along with `value_wo_version` output to assign the ephemeral credential to write-only value. Do not use this output when `var.key_vault_key` is not `null`."
  ephemeral   = true
  value       = ephemeral.tls_private_key.non_retrievable_key
}

output "non_retrievable_public_key_openssh" {
  description = "The OpenSSH encoded non-retrievable public key. This key would always be discarded after Terraform apply finished and there's no way to read the same key again. Do not use this output when `var.key_vault_key` is not `null`."
  ephemeral   = true
  value       = ephemeral.tls_private_key.non_retrievable_key.public_key_openssh
}

output "non_retrievable_public_key_pem" {
  description = "The PEM encoded non-retrievable public key. This key would always be discarded after Terraform apply finished and there's no way to read the same key again. Do not use this output when `var.key_vault_key` is not `null`."
  ephemeral   = true
  value       = ephemeral.tls_private_key.non_retrievable_key.public_key_pem
}

output "password_result" {
  description = "(String, Ephemeral) The generated random string. This password is ephemeral and will be discarded after the Terraform apply finishes if `var.key_vault_password_secret` is `null`, otherwise this value will be the password from the Key Vault secret."
  ephemeral   = true
  value       = length(ephemeral.azurerm_key_vault_secret.password) > 0 ? ephemeral.azurerm_key_vault_secret.password[0].value : ephemeral.random_password.this.result
}

output "retrievable_key_vault_key" {
  description = "The retrievable Key Vault key. Only available when `var.key_vault_key` is not `null`. This key can be used to retrieve the public and private key and other properties."
  value       = try(azurerm_key_vault_key.this[0], null)
}

output "retrievable_public_key_openssh" {
  description = "The OpenSSH encoded retrievable public key. Only available when `var.key_vault_key` is not `null`."
  value       = try(azurerm_key_vault_key.this[0].public_key_openssh, null)
}

output "retrievable_public_key_pem" {
  description = "The PEM encoded retrievable public key. Only available when `var.key_vault_key` is not `null`."
  value       = try(azurerm_key_vault_key.this[0].public_key_pem, null)
}

output "value_wo_version" {
  description = "(Number) Unix format of the `time_rotating`'s timestamp, e.g. `1581490573`. When the rotation occurs, this value will be updated to the new timestamp. This is useful for tracking when the resource was last rotated. You're encouraged to use this output as `value_wo_version` when you want to assign the ephemeral credential to write-only value."
  value       = try(time_rotating.rotating[0].unix, time_static.now[0].unix)
}
