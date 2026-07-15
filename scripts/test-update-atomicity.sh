#!/bin/bash
# Prove injected load and migration failures cannot change the saved image.
# This copies the living image to /tmp and forces update.sh down its staged
# headless path; it never opens or writes pharo/Agent.image.
set -euo pipefail
cd "$(dirname "$0")/.."

[ -f pharo/Agent.image ] || { echo "No pharo/Agent.image to copy"; exit 1; }
[ -f pharo/Agent.changes ] || { echo "No pharo/Agent.changes to copy"; exit 1; }

TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/agent-smalltalk-update-atomicity.XXXXXX")
cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT
mkdir -p "$TEST_ROOT/pharo"
cp pharo/Agent.image "$TEST_ROOT/pharo/Agent.image"
cp pharo/Agent.changes "$TEST_ROOT/pharo/Agent.changes"

before_image=$(shasum -a 256 "$TEST_ROOT/pharo/Agent.image" | awk '{print $1}')
before_changes=$(shasum -a 256 "$TEST_ROOT/pharo/Agent.changes" | awk '{print $1}')

for phase in load migration; do
  set +e
  output=$(AGENT_IMAGE="$TEST_ROOT/pharo/Agent.image" AGENT_UPDATE_FORCE_HEADLESS=1 \
    AGENT_UPDATE_FAIL_AT="$phase" ./update.sh 2>&1)
  status=$?
  set -e
  if [ "$status" -eq 0 ]; then
    echo "Expected injected $phase failure, but update succeeded"
    printf '%s\n' "$output"
    exit 1
  fi
  [ "$before_image" = "$(shasum -a 256 "$TEST_ROOT/pharo/Agent.image" | awk '{print $1}')" ] || {
    echo "Injected $phase failure changed the saved image"
    exit 1
  }
  [ "$before_changes" = "$(shasum -a 256 "$TEST_ROOT/pharo/Agent.changes" | awk '{print $1}')" ] || {
    echo "Injected $phase failure changed the saved changes file"
    exit 1
  }
done

echo "UPDATE_ATOMICITY_OK: load and migration failures left the saved pair unchanged."
