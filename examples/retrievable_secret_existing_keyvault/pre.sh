#!/usr/bin/env bash
#
# pre.sh - Provision the supporting infrastructure for the
# `retrievable_secret_existing_keyvault` example.
#
# Creates a resource group and a Key Vault (with purge protection disabled
# so it can be fully destroyed during teardown), then writes the resulting
# Key Vault id into `terraform.tfvars` for consumption by the Terraform
# configuration in this directory.
#
# The names of the created resources are persisted to `.test.env` so that
# `post.sh` can clean them up.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

LOCATION="${LOCATION:-westus2}"

# Generate a random suffix using the bash $RANDOM builtin (same approach as
# Azure/terraform-azurerm-avm-ptn-alz examples). Avoids SIGPIPE (141) from
# piping /dev/urandom through `head` under `set -o pipefail`.
SUFFIX="${RANDOM}${RANDOM}"

RG_NAME="rg-avmec-${SUFFIX}"
KV_NAME="kvavmec${SUFFIX}"

echo "Creating resource group ${RG_NAME} in ${LOCATION}..." >&2
az group create \
  --name "${RG_NAME}" \
  --location "${LOCATION}" \
  --output none

echo "Creating key vault ${KV_NAME} (purge protection disabled)..." >&2
az keyvault create \
  --name "${KV_NAME}" \
  --resource-group "${RG_NAME}" \
  --location "${LOCATION}" \
  --enable-rbac-authorization false \
  --enable-purge-protection false \
  --retention-days 7 \
  --output none

# Resolve the current principal's object id so we can grant secret permissions
# via an access policy. Try signed-in user first, then fall back to service
# principal lookup (CI runs as an SPN).
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
