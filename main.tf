ephemeral "random_password" "this" {
  length           = try(var.password.length, 10)
  lower            = try(var.password.lower, null)
  min_lower        = try(var.password.min_lower, null)
  min_numeric      = try(var.password.min_numeric, null)
  min_special      = try(var.password.min_special, null)
  min_upper        = try(var.password.min_upper, null)
  numeric          = try(var.password.numeric, null)
  override_special = try(var.password.override_special, null)
  special          = try(var.password.special, null)
  upper            = try(var.password.upper, null)
}

resource "time_rotating" "rotating" {
  count = var.time_rotating != null ? 1 : 0

  rfc3339          = var.time_rotating.rfc3339
  rotation_days    = var.time_rotating.rotation_days
  rotation_hours   = var.time_rotating.rotation_hours
  rotation_minutes = var.time_rotating.rotation_minutes
  rotation_months  = var.time_rotating.rotation_months
  rotation_rfc3339 = var.time_rotating.rotation_rfc3339
  rotation_years   = var.time_rotating.rotation_years
  triggers = merge(var.time_rotating.triggers, can(md5(jsonencode(var.password))) ? {
    password = md5(jsonencode(var.password))
    } : {}, can(md5(jsonencode(var.private_key))) ? {
    private_key = md5(jsonencode(var.private_key))
  } : {})

  lifecycle {
    precondition {
      condition     = var.key_vault_key == null
      error_message = "time_rotating cannot be used with `var.key_vault_key`. Please use `var.key_vault_key.rotation_policy.automatic` instead."
    }
  }
}

resource "time_static" "now" {
  count = var.time_rotating == null ? 1 : 0

  triggers = merge(can(md5(jsonencode(var.password))) ? {
    password = md5(jsonencode(var.password))
    } : {}, can(md5(jsonencode(var.private_key))) ? {
    private_key = md5(jsonencode(var.private_key))
  } : {})
}

resource "azurerm_key_vault_secret" "password" {
  count = var.key_vault_password_secret != null && var.password != null ? 1 : 0

  key_vault_id     = var.key_vault_password_secret.key_vault_id
  name             = var.key_vault_password_secret.name
  content_type     = var.key_vault_password_secret.content_type
  expiration_date  = try(coalesce(var.key_vault_password_secret.expiration_date, try(time_rotating.rotating[0].rotation_rfc3339, null)), null)
  not_before_date  = var.key_vault_password_secret.not_before_date
  tags             = var.key_vault_password_secret.tags
  value_wo         = ephemeral.random_password.this.result
  value_wo_version = try(time_rotating.rotating[0].unix, 0)

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

ephemeral "azurerm_key_vault_secret" "password" {
  count = var.key_vault_password_secret != null && var.password != null ? 1 : 0

  key_vault_id = azurerm_key_vault_secret.password[0].key_vault_id
  name         = azurerm_key_vault_secret.password[0].name
}
