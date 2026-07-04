#!/bin/bash
# Reload tooling from src/ into the LIVING image — widgets, facts, and all
# world state survive. Use ./build.sh only when you truly want a fresh start.
set -euo pipefail
cd "$(dirname "$0")"

VM="pharo/vm/Pharo.app/Contents/MacOS/Pharo"
IMG="pharo/Agent.image"
[ -f "$IMG" ] || { echo "No pharo/Agent.image yet — run ./build.sh first"; exit 1; }

# One writer at a time: a running GUI session holds old code in memory and
# saving it would overwrite this update. Refuse instead of racing.
if pgrep -f "Agent.image" >/dev/null 2>&1; then
  echo "A Pharo session is running on pharo/Agent.image."
  echo "Either quit it first, or update the LIVE session instead:"
  echo "  paste scripts/heal-in-image.st into a Playground and Do it."
  exit 1
fi

mkdir -p pharo/backups
cp "$IMG" "pharo/backups/pre-update-$(date +%s).image"
ls -t pharo/backups/pre-update-*.image 2>/dev/null | tail -n +6 | xargs rm -f || true

"$VM" --headless "$IMG" st scripts/update.st
echo "Tooling updated in the living image (world preserved). Backup in pharo/backups/."
