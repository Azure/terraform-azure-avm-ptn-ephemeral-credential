ephemeral "tls_private_key" "non_retrievable_key" {
  algorithm   = var.private_key.algorithm
  ecdsa_curve = var.private_key.ecdsa_curve
  rsa_bits    = var.private_key.rsa_bits
}

resource "azurerm_key_vault_key" "this" {
  count = var.key_vault_key != null ? 1 : 0

  key_opts        = var.key_vault_key.key_opts
  key_type        = var.key_vault_key.key_type
  key_vault_id    = var.key_vault_key.key_vault_id
  name            = var.key_vault_key.name
  curve           = var.key_vault_key.curve
  expiration_date = var.key_vault_key.expiration_date
  key_size        = var.key_vault_key.key_size
  not_before_date = var.key_vault_key.not_before_date
  tags            = var.key_vault_key.tags

  dynamic "rotation_policy" {
    for_each = var.key_vault_key.rotation_policy == null ? [] : [var.key_vault_key.rotation_policy]

    content {
      expire_after         = rotation_policy.value.expire_after
      notify_before_expiry = rotation_policy.value.notify_before_expiry

      dynamic "automatic" {
        for_each = rotation_policy.value.automatic == null ? [] : [rotation_policy.value.automatic]

        content {
          time_after_creation = automatic.value.time_after_creation
          time_before_expiry  = automatic.value.time_before_expiry
        }
      }
    }
  }
  dynamic "timeouts" {
    for_each = var.key_vault_key.timeouts == null ? [] : [var.key_vault_key.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}
