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

  key_vault_id = azurerm_key_vault_secret.retrievable_secret[0].key_vault_id
  name         = azurerm_key_vault_secret.retrievable_secret[0].name

  # Force this ephemeral read to be deferred to the apply phase. Without an
  # explicit dependency, both `key_vault_id` and `name` are known at plan
  # time (they are pass-through inputs of `azurerm_key_vault_secret`), which
  # causes Terraform to attempt the read during plan and fail with
  # `SecretNotFound` because the managed resource above has not yet created
  # the secret.
  depends_on = [azurerm_key_vault_secret.retrievable_secret]
}
