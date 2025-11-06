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
    password_trigger = md5(jsonencode(var.password))
    } : {}, can(md5(jsonencode(var.private_key))) ? {
    private_key_trigger = md5(jsonencode(var.private_key))
  } : {})
}

resource "time_static" "now" {
  count = var.time_rotating == null ? 1 : 0

  triggers = merge(can(md5(jsonencode(var.password))) ? {
    password_trigger = md5(jsonencode(var.password))
    } : {}, can(md5(jsonencode(var.private_key))) ? {
    private_key_trigger = md5(jsonencode(var.private_key))
  } : {})
}
