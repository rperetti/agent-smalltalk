#!/bin/bash
# Verify that native-loader warnings are assessed, current, and bounded.
set -euo pipefail
cd "$(dirname "$0")/.."

require_active=0
if [ "${1:-}" = "--full" ]; then
  require_active=1
  shift
fi

log="${1:-}"
[ -n "$log" ] && [ -r "$log" ] || {
  echo "Usage: $0 [--full] DEPENDENCY_LOAD_LOG" >&2
  exit 1
}

policy="docs/warnings.md"
policy_ids=$(sed -nE 's/^<!-- warning-policy: ([A-Z][A-Z0-9-]*) -->$/\1/p' "$policy")
observed_ids=$(sed -nE 's/^AS_WARNING ([A-Z][A-Z0-9-]*)$/\1/p' "$log")

[ -n "$policy_ids" ] || {
  echo "Warning policy has no active exception IDs: $policy" >&2
  exit 1
}

if grep -Eqi 'NewUndeclaredWarning|Warning: Warning: Package .*depends on the following classes|is Undeclared' "$log"; then
  echo "Native loader emitted an unassessed compiler or package warning." >&2
  exit 1
fi

while IFS= read -r id; do
  [ -n "$id" ] || continue
  policy_count=$(printf '%s\n' "$policy_ids" | grep -Fxc "$id" || true)
  if [ "$policy_count" -ne 1 ]; then
    echo "Warning policy ID $id must appear exactly once in $policy; found $policy_count." >&2
    exit 1
  fi
  if ! grep -Eq "^### $id — (Low|Medium|High|Critical)( |$)" "$policy"; then
    echo "Warning policy ID $id has no severity heading in $policy." >&2
    exit 1
  fi
done <<EOF
$policy_ids
EOF

while IFS= read -r id; do
  [ -n "$id" ] || continue
  if ! printf '%s\n' "$policy_ids" | grep -Fxq "$id"; then
    echo "Native loader emitted an unknown warning ID: $id" >&2
    exit 1
  fi
done <<EOF
$observed_ids
EOF

if [ "$require_active" -eq 1 ]; then
  while IFS= read -r id; do
    [ -n "$id" ] || continue
    count=$(printf '%s\n' "$observed_ids" | grep -Fxc "$id" || true)
    if [ "$count" -ne 1 ]; then
      echo "Warning policy ID $id must appear exactly once in the native loader log; found $count." >&2
      exit 1
    fi
  done <<EOF
$policy_ids
EOF
fi

echo "WARNING_POLICY_OK: assessed loader warnings match $policy."
