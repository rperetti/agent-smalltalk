#!/bin/bash
# Reload tooling from src/ into the LIVING image — widgets, facts, and all
# world state survive. Use ./build.sh only when you truly want a fresh start.
set -euo pipefail
cd "$(dirname "$0")"

VM="pharo/vm/Pharo.app/Contents/MacOS/Pharo"
IMG="pharo/Agent.image"
[ -f "$IMG" ] || { echo "No pharo/Agent.image yet — run ./build.sh first"; exit 1; }

# One writer at a time: a running GUI session holds old code in memory and
# saving it would overwrite a file-level update. If a session is running,
# update IT over its localhost listener instead of touching the file.
if pgrep -f "Agent.image" >/dev/null 2>&1; then
  echo "Live session detected — updating it in place via localhost:8807..."
  if curl -s -f -m 180 -X POST "http://127.0.0.1:8807/update" >/dev/null 2>&1; then
    echo "Live session updated (migrations + save run on its UI thread)."
    exit 0
  fi
  echo "The session does not answer on :8807 (built before AgentRemote)."
  echo "One-time bootstrap: paste scripts/heal-in-image.st into a Playground"
  echo "and Do it — after that, updates reach live sessions automatically."
  exit 1
fi

mkdir -p pharo/backups
cp "$IMG" "pharo/backups/pre-update-$(date +%s).image"
ls -t pharo/backups/pre-update-*.image 2>/dev/null | tail -n +6 | xargs rm -f || true

"$VM" --headless "$IMG" st scripts/update.st
echo "Tooling updated in the living image (world preserved). Backup in pharo/backups/."
