#!/bin/bash
# Honest local release signal: deterministic checks only, no provider calls.
set -euo pipefail
cd "$(dirname "$0")"

./test.sh
./smoke.sh automations
./smoke.sh provider-syntax
echo "VERIFY_ALL_OK: deterministic SUnit and smoke gates passed."
