resource "azurerm_key_vault_secret" "retrievable_secret" {
  count = var.retrievable_secret != null ? 1 : 0

  key_vault_id     = var.retrievable_secret.key_vault_id
  name             = var.retrievable_secret.name
  content_type     = var.retrievable_secret.content_type
  expiration_date  = try(coalesce(var.retrievable_secret.expiration_date, try(time_rotating.rotating[0].rotation_rfc3339, null)), null)
  not_before_date  = var.retrievable_secret.not_before_date
  tags             = var.retrievable_secret.tags
  value_wo         = try(ephemeral.tls_private_key.this[0].private_key_pem, ephemeral.random_password.this.result)
  value_wo_version = try(time_rotating.rotating[0].unix, time_static.now[0].unix)

  dynamic "timeouts" {
    for_each = var.retrievable_secret.timeouts == null ? [] : [var.retrievable_secret.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}

ephemeral "azurerm_key_vault_secret" "retrievable_secret" {
  count = var.retrievable_secret != null ? 1 : 0

  # Derive `key_vault_id` from the managed secret's computed
  # `resource_versionless_id` attribute (only known after apply) using the
  # `azapi` provider-defined `parse_resource_id` function. This makes the
  # ephemeral block's configuration unknown at plan time, forcing the read
  # to be deferred until apply, after the secret has been created. A plain
  # reference to `azurerm_key_vault_secret.retrievable_secret[0].key_vault_id`
  # (or a `depends_on`) is not sufficient because both `key_vault_id` and
  # `name` are pass-through inputs that remain known at plan time, which
  # would cause Terraform to attempt the read during plan and fail with
  # `SecretNotFound`.
  key_vault_id = provider::azapi::parse_resource_id("Microsoft.KeyVault/vaults/secrets", azurerm_key_vault_secret.retrievable_secret[0].resource_versionless_id).parent_id
  name         = azurerm_key_vault_secret.retrievable_secret[0].name
}
