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
