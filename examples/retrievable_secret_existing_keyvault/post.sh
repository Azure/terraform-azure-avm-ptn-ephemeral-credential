#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -d "$SCRIPT_DIR/prereqs" ]; then
  cd "$SCRIPT_DIR/prereqs"
  terraform destroy -auto-approve || true
fi

rm -f "$SCRIPT_DIR/terraform.tfvars"