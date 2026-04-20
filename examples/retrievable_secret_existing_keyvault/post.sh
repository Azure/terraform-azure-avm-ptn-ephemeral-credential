#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ -d "$SCRIPT_DIR/lib" ]; then
  cd "$SCRIPT_DIR/lib"
  terraform destroy -auto-approve || true
fi

rm -f "$SCRIPT_DIR/terraform.tfvars"