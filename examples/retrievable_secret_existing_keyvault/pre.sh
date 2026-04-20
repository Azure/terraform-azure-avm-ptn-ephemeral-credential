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

LOCATION="${LOCATION:-westus2}"

SUFFIX="${RANDOM}"

RG_NAME="rg-avmec-${SUFFIX}"
KV_NAME="kvavmec${SUFFIX}"

echo "Creating resource group ${RG_NAME} in ${LOCATION}..." >&2
az group create \
  --name "${RG_NAME}" \
  --location "${LOCATION}" \
  --output none

echo "Creating key vault ${KV_NAME}..." >&2
az keyvault create \
  --name "${KV_NAME}" \
  --resource-group "${RG_NAME}" \
  --location "${LOCATION}" \
  --enable-rbac-authorization false \
  --retention-days 7 \
  --output none

# Resolve the current principal's object id (signed-in user or SPN).
OBJECT_ID="$(az ad signed-in-user show --query id -o tsv 2>/dev/null || true)"
if [ -z "${OBJECT_ID}" ]; then
  SP_APP_ID="$(az account show --query user.name -o tsv)"
  OBJECT_ID="$(az ad sp show --id "${SP_APP_ID}" --query id -o tsv)"
fi

echo "Granting secret permissions to object id ${OBJECT_ID}..." >&2
az keyvault set-policy \
  --name "${KV_NAME}" \
  --object-id "${OBJECT_ID}" \
  --secret-permissions get list set delete recover backup restore purge \
  --output none

KV_ID="$(az keyvault show --name "${KV_NAME}" --resource-group "${RG_NAME}" --query id -o tsv)"

cat > terraform.tfvars <<EOF
key_vault_id = "${KV_ID}"
secret_name  = "ephemeral-test-password-${SUFFIX}"
EOF

cat > .test.env <<EOF
RG_NAME=${RG_NAME}
KV_NAME=${KV_NAME}
EOF

echo "Wrote terraform.tfvars and .test.env (kv=${KV_NAME}, rg=${RG_NAME})." >&2
