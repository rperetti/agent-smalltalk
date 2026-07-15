#!/bin/bash
# Reload tooling from src/ into the living image without committing a failed
# load to disk. The candidate is copied, manifest-marked, and preflighted in a
# disposable image before either delivery path sees it.
set -euo pipefail
cd "$(dirname "$0")"

IMG="${AGENT_IMAGE:-pharo/Agent.image}"
CHANGES="${IMG%.image}.changes"
[ -f "$IMG" ] || { echo "No image at $IMG — run ./build.sh first"; exit 1; }
[ -f "$CHANGES" ] || { echo "Missing matching changes file: $CHANGES"; exit 1; }

if [ -n "${PHARO_VM:-}" ]; then
  VM="$PHARO_VM"
elif [ -x "pharo/vm/Pharo.app/Contents/MacOS/Pharo" ]; then
  VM="pharo/vm/Pharo.app/Contents/MacOS/Pharo"
else
  VM=$(find pharo/vm -type f \( -name Pharo -o -name pharo \) -perm -111 -print -quit)
fi
[ -n "${VM:-}" ] && [ -x "$VM" ] || {
  echo "No Pharo VM found. Set PHARO_VM or install one under pharo/vm/."
  exit 1
}

STAGE_ROOT=$(mktemp -d "pharo/.update-stage.XXXXXX")
cleanup() {
  rm -rf "$STAGE_ROOT"
}
trap cleanup EXIT

cp -R src "$STAGE_ROOT/"
CANDIDATE_SRC="$STAGE_ROOT/src"

SOURCE_SHA256=$(
  cd "$CANDIDATE_SRC"
  find . -type f -print | LC_ALL=C sort | while IFS= read -r file; do
    shasum -a 256 "$file"
  done | shasum -a 256 | awk '{print $1}'
)
GIT_REVISION=$(git rev-parse --verify HEAD)
MANIFEST="AS_UPDATE_V1 git:${GIT_REVISION} sha256:${SOURCE_SHA256}"
MARKER="$CANDIDATE_SRC/AgentSmalltalk-Core/AgentUpdateBuild.class.st"

printf '%s\n' \
  '"' \
  'I bind this private staged source tree to the manifest that update.sh preflighted.' \
  '"' \
  'Class {' \
  "\t#name : 'AgentUpdateBuild'," \
  "\t#superclass : 'Object'," \
  "\t#category : 'AgentSmalltalk-Core'," \
  "\t#package : 'AgentSmalltalk-Core'" \
  '}' \
  '' \
  "{ #category : 'accessing' }" \
  'AgentUpdateBuild class >> manifest [' \
  "\t^ '${MANIFEST}'" \
  ']' > "$MARKER"

has_exact_line() {
  local output="$1"
  local expected="$2"
  [ "$(printf '%s\n' "$output" | grep -Fxc "$expected" || true)" = "1" ]
}

set +e
PREFLIGHT_OUTPUT=$(AGENT_SOURCE_DIR="$CANDIDATE_SRC" AGENT_UPDATE_MANIFEST="$MANIFEST" ./test.sh 2>&1)
PREFLIGHT_STATUS=$?
set -e
if [ "$PREFLIGHT_STATUS" -ne 0 ] || ! has_exact_line "$PREFLIGHT_OUTPUT" "UPDATE_PREFLIGHT_OK $MANIFEST"; then
  echo "!! UPDATE PREFLIGHT FAILED — the living image was not touched."
  printf '%s\n' "$PREFLIGHT_OUTPUT" | tail -40
  exit 1
fi
echo "Candidate preflight passed: $MANIFEST"

if [ "${AGENT_UPDATE_FORCE_HEADLESS:-0}" != "1" ] && pgrep -f "$(basename "$IMG")" >/dev/null 2>&1; then
  set +e
  PING_RESPONSE=$(curl -sS -m 5 "http://127.0.0.1:8807/ping")
  PING_STATUS=$?
  set -e
  if [ "$PING_STATUS" -ne 0 ] || [ "$PING_RESPONSE" != "agent-smalltalk alive update-v1" ]; then
    echo "!! LIVE UPDATE NOT SENT — the running listener does not support the staged update protocol."
    echo "!! Quit it without saving, then re-run ./update.sh to take the verified headless path."
    exit 1
  fi
  echo "Live session detected — delivering the preflighted candidate via localhost:8807..."
  set +e
  CURL_OUTPUT=$(printf '%s\n%s' "$CANDIDATE_SRC" "$MANIFEST" | \
    curl -sS -m 180 -X POST "http://127.0.0.1:8807/update" --data-binary @- -w $'\n%{http_code}')
  CURL_STATUS=$?
  set -e
  HTTP_STATUS="${CURL_OUTPUT##*$'\n'}"
  RESPONSE="${CURL_OUTPUT%$'\n'*}"
  if [ "$CURL_STATUS" -eq 0 ] && [ "$HTTP_STATUS" = "200" ] && [ "$RESPONSE" = "UPDATE_OK $MANIFEST" ]; then
    echo "Live session updated, manifest-verified, and saved."
    exit 0
  fi
  echo "!! LIVE UPDATE FAILED — the session was not saved as a valid update."
  printf '%s\n' "${RESPONSE:-<no response; listener down or pre-protocol build>}"
  exit 1
fi

mkdir -p "$STAGE_ROOT/pharo"
STAGED_IMAGE="$STAGE_ROOT/pharo/Agent.image"
STAGED_CHANGES="${STAGED_IMAGE%.image}.changes"
cp "$IMG" "$STAGED_IMAGE"
cp "$CHANGES" "$STAGED_CHANGES"

set +e
HEADLESS_OUTPUT=$(env AGENT_UPDATE_MANIFEST="$MANIFEST" "$VM" --headless "$STAGED_IMAGE" st scripts/update.st 2>&1)
HEADLESS_STATUS=$?
set -e
if [ "$HEADLESS_STATUS" -ne 0 ] || ! has_exact_line "$HEADLESS_OUTPUT" "UPDATE_OK $MANIFEST"; then
  echo "!! UPDATE FAILED — the living image was not changed."
  printf '%s\n' "$HEADLESS_OUTPUT" | grep -E "UPDATE_FAILED|Error|error" | head -10 || true
  exit 1
fi

BACKUP_DIR="pharo/backups"
BACKUP_IMAGE="$BACKUP_DIR/pre-update-$(date +%s)-$$.image"
mkdir -p "$BACKUP_DIR"
cp "$IMG" "$BACKUP_IMAGE"
cp "$CHANGES" "${BACKUP_IMAGE%.image}.changes"

mv "$STAGED_CHANGES" "$CHANGES"
mv "$STAGED_IMAGE" "$IMG"

ls -t "$BACKUP_DIR"/pre-update-*.image 2>/dev/null | tail -n +6 | while IFS= read -r stale; do
  rm -f "$stale" "${stale%.image}.changes"
done

echo "Tooling updated from the verified staged image. Backup: $BACKUP_IMAGE"
