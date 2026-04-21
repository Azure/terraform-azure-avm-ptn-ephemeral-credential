# Retrievable secret with pre-existing Key Vault example

This example exercises `retrievable_secret` against a Key Vault that is created **outside** of the Terraform configuration (by the `pre.sh` script).

This reproduces the scenario that previously failed at `terraform plan` with `SecretNotFound`, because the ephemeral `azurerm_key_vault_secret` would attempt to read the not-yet-created secret during plan when both `key_vault_id` and `name` were known. The fix is an explicit `depends_on` from the ephemeral block to the managed `azurerm_key_vault_secret` resource so the read is deferred to apply.

The `pre.sh` script:

- Generates a random suffix and writes `terraform.tfvars` containing the Key Vault id.
- Creates a resource group and a Key Vault. The Key Vault is configured with **purge protection disabled** so it can be destroyed by `post.sh`.

The `post.sh` script deletes and purges the Key Vault, then deletes the resource group.
