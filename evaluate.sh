#!/bin/bash
# Explicit, paid provider evaluations. Each name runs cold in its own image and
# emits a JSON evidence record; this is intentionally separate from verify-all.
set -euo pipefail
cd "$(dirname "$0")"

if [ "$#" -eq 0 ]; then
  set -- fact-retrieval fact-baseline context-adversarial fact-widget widget modify textfield facts tools selection reactive
fi

for name in "$@"; do
  ./smoke.sh --provider "$name"
done

echo "EVALUATIONS_OK: provider evidence records were written."
