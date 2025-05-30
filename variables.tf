variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "key_vault_key" {
  type = object({
    curve           = optional(string)
    expiration_date = optional(string)
    key_opts        = list(string)
    key_size        = optional(number)
    key_type        = string
    key_vault_id    = string
    name            = string
    not_before_date = optional(string)
    tags            = optional(map(string))
    rotation_policy = optional(object({
      expire_after         = optional(string)
      notify_before_expiry = optional(string)
      automatic = optional(object({
        time_after_creation = optional(string)
        time_before_expiry  = optional(string)
      }))
    }))
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  })
  default     = null
  description = <<-EOT
 - `curve` - (Optional) Specifies the curve to use when creating an `EC` key. Possible values are `P-256`, `P-256K`, `P-384`, and `P-521`. This field will be required in a future release if `key_type` is `EC` or `EC-HSM`. The API will default to `P-256` if nothing is specified. Changing this forces a new resource to be created.
 - `expiration_date` - (Optional) Expiration UTC datetime (Y-m-d'T'H:M:S'Z').
 - `key_opts` - (Required) A list of JSON web key operations. Possible values include: `decrypt`, `encrypt`, `sign`, `unwrapKey`, `verify` and `wrapKey`. Please note these values are case sensitive.
 - `key_size` - (Optional) Specifies the Size of the RSA key to create in bytes. For example, 1024 or 2048. *Note*: This field is required if `key_type` is `RSA` or `RSA-HSM`. Changing this forces a new resource to be created.
 - `key_type` - (Required) Specifies the Key Type to use for this Key Vault Key. Possible values are `EC` (Elliptic Curve), `EC-HSM`, `RSA` and `RSA-HSM`. Changing this forces a new resource to be created.
 - `key_vault_id` - (Required) The ID of the Key Vault where the Key should be created. Changing this forces a new resource to be created.
 - `name` - (Required) Specifies the name of the Key Vault Key. Changing this forces a new resource to be created.
 - `not_before_date` - (Optional) Key not usable before the provided UTC datetime (Y-m-d'T'H:M:S'Z').
 - `tags` - (Optional) A mapping of tags to assign to the resource.

 ---
 `rotation_policy` block supports the following:
 - `expire_after` - (Optional) Expire a Key Vault Key after given duration as an [ISO 8601 duration](https://en.wikipedia.org/wiki/ISO_8601#Durations).
 - `notify_before_expiry` - (Optional) Notify at a given duration before expiry as an [ISO 8601 duration](https://en.wikipedia.org/wiki/ISO_8601#Durations).

 ---
 `automatic` block supports the following:
 - `time_after_creation` - (Optional) Rotate automatically at a duration after create as an [ISO 8601 duration](https://en.wikipedia.org/wiki/ISO_8601#Durations).
 - `time_before_expiry` - (Optional) Rotate automatically at a duration before expiry as an [ISO 8601 duration](https://en.wikipedia.org/wiki/ISO_8601#Durations).

 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 30 minutes) Used when creating the Key Vault Key.
 - `delete` - (Defaults to 30 minutes) Used when deleting the Key Vault Key.
 - `read` - (Defaults to 30 minutes) Used when retrieving the Key Vault Key.
 - `update` - (Defaults to 30 minutes) Used when updating the Key Vault Key.
EOT
}

variable "key_vault_password_secret" {
  type = object({
    content_type    = optional(string)
    expiration_date = optional(string)
    key_vault_id    = string
    name            = string
    not_before_date = optional(string)
    tags            = optional(map(string))
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
  })
  default     = null
  description = <<-EOT
 - `content_type` - (Optional) Specifies the content type for the Key Vault Secret.
 - `expiration_date` - (Optional) Expiration UTC datetime (Y-m-d'T'H:M:S'Z').
 - `key_vault_id` - (Required) The ID of the Key Vault where the Secret should be created. Changing this forces a new resource to be created.
 - `not_before_date` - (Optional) Key not usable before the provided UTC datetime (Y-m-d'T'H:M:S'Z').
 - `tags` - (Optional) A mapping of tags to assign to the resource.
 - `value` - (Optional) Specifies the value of the Key Vault Secret. Changing this will create a new version of the Key Vault Secret.

 ---
 `timeouts` block supports the following:
 - `create` - (Defaults to 30 minutes) Used when creating the Key Vault Secret.
 - `delete` - (Defaults to 30 minutes) Used when deleting the Key Vault Secret.
 - `read` - (Defaults to 30 minutes) Used when retrieving the Key Vault Secret.
 - `update` - (Defaults to 30 minutes) Used when updating the Key Vault Secret.
EOT

  validation {
    condition     = var.key_vault_password_secret == null || var.password != null
    error_message = "The `key_vault_password_secret` variable can only be set when the `password` variable is set."
  }
}

variable "password" {
  type = object({
    length           = number
    lower            = optional(bool)
    min_lower        = optional(number)
    min_numeric      = optional(number)
    min_special      = optional(number)
    min_upper        = optional(number)
    number           = optional(bool)
    numeric          = optional(bool)
    override_special = optional(string)
    special          = optional(bool)
    upper            = optional(bool)
  })
  default     = null
  description = <<-EOT
 - `keepers` -
 - `length` -
 - `lower` - (Boolean) Include lowercase alphabet characters in the result. Default value is `true`.
 - `min_lower` - (Number) Minimum number of lowercase alphabet characters in the result. Default value is `0`.
 - `min_numeric` - (Number) Minimum number of numeric characters in the result. Default value is `0`.
 - `min_special` - (Number) Minimum number of special characters in the result. Default value is `0`.
 - `min_upper` - (Number) Minimum number of uppercase alphabet characters in the result. Default value is `0`.
 - `numeric` - (Boolean) Include numeric characters in the result. Default value is true. If `numeric`, `upper`, `lower`, and `special` are all configured, at least one of them must be set to `true`.
 - `override_special` - (String) Supply your own list of special characters to use for string generation. This overrides the default character list in the special argument. The `special` argument must still be set to true for any overwritten characters to be used in generation.
 - `special` - (Boolean) Include special characters in the result. These are `!@#$%&*()-_=+[]{}<>:?`. Default value is `true`.
 - `upper` - (Boolean) Include uppercase alphabet characters in the result. Default value is `true`.
EOT
}

variable "private_key" {
  type = object({
    algorithm   = string
    ecdsa_curve = optional(string)
    rsa_bits    = optional(number)
  })
  default = {
    algorithm = "RSA"
    rsa_bits  = 2048
  }
  description = <<-EOT
 - `algorithm` - (String) Name of the algorithm to use when generating the private key. Currently-supported values are: `RSA`, `ECDSA`, `ED25519`.
 - `ecdsa_curve` - (String) When `algorithm` is `ECDSA`, the name of the elliptic curve to use. Currently-supported values are: `P224`, `P256`, `P384`, `P521`. (default: `P224`).
 - `rsa_bits` - (Number) When `algorithm` is RSA, the size of the generated RSA key, in bits (default: `2048`).
EOT
  nullable    = false
}

variable "time_rotating" {
  type = object({
    rfc3339          = optional(string)
    rotation_days    = optional(number)
    rotation_hours   = optional(number)
    rotation_minutes = optional(number)
    rotation_months  = optional(number)
    rotation_rfc3339 = optional(string)
    rotation_years   = optional(number)
    triggers         = optional(map(string), {})
  })
  default     = null
  description = <<-EOT
 Rotating policy for ephemeral credential. This will trigger recreation of the resource when the current time has passed the rotation timestamp.
 - `rfc3339` - (String) Base timestamp in [RFC3339](https://datatracker.ietf.org/doc/html/rfc3339#section-5.8) format (see [RFC3339 time string](https://tools.ietf.org/html/rfc3339#section-5.8) e.g., `YYYY-MM-DDTHH:MM:SSZ`). Defaults to the current time.
 - `rotation_days` - (Number) Number of days to add to the base timestamp to configure the rotation timestamp. When the current time has passed the rotation timestamp, the resource will trigger recreation. At least one of the 'rotation_' arguments must be configured.
 - `rotation_hours` - (Number) Number of hours to add to the base timestamp to configure the rotation timestamp. When the current time has passed the rotation timestamp, the resource will trigger recreation. At least one of the 'rotation_' arguments must be configured.
 - `rotation_minutes` - (Number) Number of minutes to add to the base timestamp to configure the rotation timestamp. When the current time has passed the rotation timestamp, the resource will trigger recreation. At least one of the 'rotation_' arguments must be configured.
 - `rotation_months` - (Number) Number of months to add to the base timestamp to configure the rotation timestamp. When the current time has passed the rotation timestamp, the resource will trigger recreation. At least one of the 'rotation_' arguments must be configured.
 - `rotation_rfc3339` - (String) Configure the rotation timestamp with an [RFC3339](https://datatracker.ietf.org/doc/html/rfc3339#section-5.8) format of the offset timestamp. When the current time has passed the rotation timestamp, the resource will trigger recreation. At least one of the 'rotation_' arguments must be configured.
 - `rotation_years` - (Number) Number of years to add to the base timestamp to configure the rotation timestamp. When the current time has passed the rotation timestamp, the resource will trigger recreation. At least one of the 'rotation_' arguments must be configured.
 - `triggers` - (Map of String) Arbitrary map of values that, when changed, will trigger a new base timestamp value to be saved. These conditions recreate the resource in addition to other rotation arguments. See [the main provider documentation](../index.md) for more information.
EOT

  validation {
    condition     = var.time_rotating == null || (var.password != null || var.private_key != null)
    error_message = "The `password_time_rotating` variable can only be set when either one of `password` and `private_key` variable is set."
  }
}
