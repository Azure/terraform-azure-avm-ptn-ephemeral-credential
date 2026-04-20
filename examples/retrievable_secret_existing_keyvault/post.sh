#!/usr/bin/env bash
#
# post.sh - Tear down the supporting infrastructure created by `pre.sh` for
# the `retrievable_secret_existing_keyvault` example.
#
# Reads the Key Vault and resource group names from `.test.env`, deletes
# and purges the Key Vault, then deletes the resource group.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if [ ! -f .test.env ]; then
  echo "No .test.env found; nothing to clean up." >&2
  exit 0
fi

# shellcheck disable=SC1091
. .test.env

if [ -n "${KV_NAME:-}" ]; then
  echo "Deleting key vault ${KV_NAME}..." >&2
  az keyvault delete --name "${KV_NAME}" --output none || true
  echo "Purging key vault ${KV_NAME}..." >&2
  az keyvault purge --name "${KV_NAME}" --output none || true
fi

if [ -n "${RG_NAME:-}" ]; then
  echo "Deleting resource group ${RG_NAME}..." >&2
  az group delete --name "${RG_NAME}" --yes --no-wait --output none || true
fi

rm -f .test.env terraform.tfvars
