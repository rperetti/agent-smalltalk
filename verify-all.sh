#!/bin/bash
# Honest local release signal: deterministic checks only, no provider calls.
set -euo pipefail
cd "$(dirname "$0")"

./scripts/check-backlog-order.sh
./test.sh
./smoke.sh automations
./smoke.sh provider-syntax
echo "VERIFY_ALL_OK: backlog, deterministic SUnit, and smoke gates passed."
