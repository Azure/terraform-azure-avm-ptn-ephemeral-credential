# Retrievable secret with pre-existing Key Vault example

This example exercises `retrievable_secret` against a Key Vault created by a separate prerequisite Terraform configuration using `pre.ps1`.

The existing vault ID and secret name are known during plan. The module derives the ephemeral read's vault ID from the managed secret's computed resource ID, deferring the read until apply so it does not fail with `SecretNotFound` before the secret is created.

Run the hooks only in an approved test environment. `pre.ps1` initializes and applies `tests/fixtures/retrievable_secret_existing_keyvault`, then writes the Key Vault ID and secret name to `terraform.tfvars`. The configuration's resource addresses are unchanged. The hooks explicitly retain state at this example's `prereqs/terraform.tfstate`, workspace state at `prereqs/terraform.tfstate.d`, and initialization data at `prereqs/.terraform` (or the caller's existing `TF_DATA_DIR`). No existing state needs to be moved.

`post.ps1` destroys the prerequisite resources and removes `terraform.tfvars` only after successful cleanup. Failed cleanup retains local state and outputs, but a hosting tool that deletes its staging directory can still discard them. Terraform failures are reported rather than ignored. The prerequisite vault has purge protection disabled, and the fixture's regions-module telemetry is disabled.
