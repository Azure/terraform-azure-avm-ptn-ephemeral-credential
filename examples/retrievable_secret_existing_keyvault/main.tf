module "retrievable_password" {
  source = "../../"

  enable_telemetry = var.enable_telemetry
  password = {
    length      = 20
    special     = true
    upper       = true
    lower       = true
    numeric     = true
    min_lower   = 2
    min_upper   = 2
    min_numeric = 2
    min_special = 2
  }
  retrievable_secret = {
    key_vault_id = var.key_vault_id
    name         = var.secret_name
  }
}


