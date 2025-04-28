ephemeral "random_password" "this" {
  count = var.password != null ? 1 : 0

  length           = var.password.length
  keepers          = var.password.keepers
  lower            = var.password.lower
  min_lower        = var.password.min_lower
  min_numeric      = var.password.min_numeric
  min_special      = var.password.min_special
  min_upper        = var.password.min_upper
  numeric          = var.password.numeric
  override_special = var.password.override_special
  special          = var.password.special
  upper            = var.password.upper
}

ephemeral "tls_private_key" "this" {
  count = var.private_key != null ? 1 : 0

  algorithm   = var.private_key.algorithm
  ecdsa_curve = var.private_key.ecdsa_curve
  rsa_bits    = var.private_key.rsa_bits
}

resource "time_rotating" "this" {
  count = var.time_rotating != null ? 1 : 0

  rfc3339          = var.time_rotating.rfc3339
  rotation_days    = var.time_rotating.rotation_days
  rotation_hours   = var.time_rotating.rotation_hours
  rotation_minutes = var.time_rotating.rotation_minutes
  rotation_months  = var.time_rotating.rotation_months
  rotation_rfc3339 = var.time_rotating.rotation_rfc3339
  rotation_years   = var.time_rotating.rotation_years
  triggers         = var.time_rotating.triggers
}

resource "azurerm_key_vault_secret" "password" {
  count = var.key_vault_password_secret != null && var.password != null ? 1 : 0

  key_vault_id     = var.key_vault_password_secret.key_vault_id
  name             = var.key_vault_password_secret.name
  content_type     = var.key_vault_password_secret.content_type
  expiration_date  = try(coalesce(var.key_vault_password_secret.expiration_date, try(time_rotating.this[0].rotation_rfc3339, null)), null)
  not_before_date  = var.key_vault_password_secret.not_before_date
  tags             = var.key_vault_password_secret.tags
  value_wo         = ephemeral.random_password.this[0].result
  value_wo_version = try(time_rotating.this[0].unix, 0)

  dynamic "timeouts" {
    for_each = var.key_vault_password_secret.timeouts == null ? [] : [var.key_vault_password_secret.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }
}
