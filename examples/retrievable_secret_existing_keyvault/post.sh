#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

if ! az account show --output none 2>/dev/null; then
  : "${ARM_CLIENT_ID:?ARM_CLIENT_ID is required for OIDC login}"
  : "${ARM_TENANT_ID:?ARM_TENANT_ID is required for OIDC login}"
  : "${ARM_SUBSCRIPTION_ID:?ARM_SUBSCRIPTION_ID is required for OIDC login}"
  : "${ARM_OIDC_REQUEST_TOKEN:?ARM_OIDC_REQUEST_TOKEN is required for OIDC login}"
  : "${ARM_OIDC_REQUEST_URL:?ARM_OIDC_REQUEST_URL is required for OIDC login}"

  echo "Logging in to Azure via OIDC..." >&2
  FEDERATED_TOKEN="$(curl -sSL -H "Authorization: Bearer ${ARM_OIDC_REQUEST_TOKEN}" \
    "${ARM_OIDC_REQUEST_URL}&audience=api://AzureADTokenExchange" | jq -r '.value')"
  az login --service-principal \
    --username "${ARM_CLIENT_ID}" \
    --tenant "${ARM_TENANT_ID}" \
    --federated-token "${FEDERATED_TOKEN}" \
    --output none
  az account set --subscription "${ARM_SUBSCRIPTION_ID}" --output none
fi

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
