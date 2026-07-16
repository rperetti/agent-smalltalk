#!/bin/bash
# Exercise the warning-policy parser without loading a Pharo image.
set -euo pipefail
cd "$(dirname "$0")/.."

fixtures="scripts/warning-policy-fixtures"

./scripts/check-warning-policy.sh --full "$fixtures/accepted.log"

for fixture in missing.log unknown.log unresolved.log; do
  if ./scripts/check-warning-policy.sh --full "$fixtures/$fixture" >/dev/null 2>&1; then
    echo "Warning-policy fixture unexpectedly passed: $fixture" >&2
    exit 1
  fi
done

echo "WARNING_POLICY_TEST_OK: accepted, stale, unknown, and raw-warning cases checked."
