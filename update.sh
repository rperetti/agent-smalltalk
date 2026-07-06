#!/bin/bash
# Reload tooling from src/ into the LIVING image — widgets, facts, and all
# world state survive. Use ./build.sh only when you truly want a fresh start.
#
# GUARDED: a load that silently leaves stale code running (e.g. a syntax error
# aborting a package) is worse than a loud failure. Both delivery paths now
# require an explicit UPDATE_OK token proving the load fully took; anything
# else is a hard, loud failure.
set -euo pipefail
cd "$(dirname "$0")"

VM="pharo/vm/Pharo.app/Contents/MacOS/Pharo"
IMG="pharo/Agent.image"
[ -f "$IMG" ] || { echo "No pharo/Agent.image yet — run ./build.sh first"; exit 1; }

# One writer at a time: a running GUI session holds code in memory and saving
# it would overwrite a file-level update. If a session is running, update IT
# over its localhost listener instead of touching the file.
if pgrep -f "Agent.image" >/dev/null 2>&1; then
  echo "Live session detected — updating it in place via localhost:8807..."
  RESP=$(curl -s -m 180 -X POST "http://127.0.0.1:8807/update" 2>/dev/null || true)
  if [ "$RESP" = "UPDATE_OK" ]; then
    echo "Live session updated and verified (UPDATE_OK)."
    exit 0
  fi
  echo "!! UPDATE FAILED — the running session was NOT updated."
  echo "!! Session response: ${RESP:-<no response; listener down or pre-guard build>}"
  echo "!! Fix the cause, or quit the session and re-run to update the file."
  exit 1
fi

mkdir -p pharo/backups
cp "$IMG" "pharo/backups/pre-update-$(date +%s).image"
ls -t pharo/backups/pre-update-*.image 2>/dev/null | tail -n +6 | xargs rm -f || true

OUT=$("$VM" --headless "$IMG" st scripts/update.st 2>&1) || true
if echo "$OUT" | grep -q "UPDATE_OK"; then
  echo "Tooling updated in the living image and verified (UPDATE_OK). Backup in pharo/backups/."
  exit 0
fi
echo "!! UPDATE FAILED — the image was NOT changed (restore from pharo/backups/ if needed)."
echo "$OUT" | grep -E "UPDATE_FAILED|Error|error" | head -10
exit 1
