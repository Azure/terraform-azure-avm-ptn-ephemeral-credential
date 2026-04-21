#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/prereqs"

terraform init
terraform apply -auto-approve

KV_ID="$(terraform output -raw key_vault_id)"
SECRET_NAME="$(terraform output -raw secret_name)"

cd "$SCRIPT_DIR"

cat > terraform.tfvars <<EOF
key_vault_id = "${KV_ID}"
secret_name  = "${SECRET_NAME}"
EOF
