variable "key_vault_id" {
  type        = string
  description = "The resource ID of an existing Key Vault to write the retrievable secret into. Provided by `pre.sh` via `terraform.tfvars`."
}

variable "location" {
  type        = string
  description = "The Azure region where the existing Key Vault resides. Provided by `pre.sh` via `terraform.tfvars`."
}

variable "enable_telemetry" {
  type        = bool
  default     = false
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
}

variable "secret_name" {
  type        = string
  default     = "ephemeral-test-password"
  description = "The name of the Key Vault secret to create."
}
