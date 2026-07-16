#!/bin/bash
# Build a disposable image from the pristine Pharo image and run SUnit there.
# The user's living Agent.image is deliberately never opened or modified:
# saved windows, processes, generated classes, and facts are product state,
# not a reproducible test fixture.
set -euo pipefail
cd "$(dirname "$0")"

SOURCE_DIR="${AGENT_SOURCE_DIR:-$PWD/src}"
[ -d "$SOURCE_DIR" ] || {
  echo "No source directory found: $SOURCE_DIR"
  exit 1
}
SOURCE_DIR=$(cd "$SOURCE_DIR" && pwd -P)

if [ -n "${PHARO_VM:-}" ]; then
  VM="$PHARO_VM"
elif [ -x "pharo/vm/Pharo.app/Contents/MacOS/Pharo" ]; then
  VM="pharo/vm/Pharo.app/Contents/MacOS/Pharo"
else
  VM=$(find pharo/vm -type f -name pharo -perm -111 -print -quit)
fi

[ -n "${VM:-}" ] && [ -x "$VM" ] || {
  echo "No Pharo VM found. Set PHARO_VM or install one under pharo/vm/."
  exit 1
}

if [ -n "${PHARO_PRISTINE:-}" ]; then
  PRISTINE="$PHARO_PRISTINE"
else
  PRISTINE=$(find pharo -maxdepth 1 -name 'Pharo*-64bit-*.image' -print -quit)
fi

[ -n "${PRISTINE:-}" ] && [ -f "$PRISTINE" ] || {
  echo "No pristine Pharo image found. Set PHARO_PRISTINE or install one under pharo/."
  exit 1
}

TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/agent-smalltalk-test.XXXXXX")
mkdir -p "$TEST_ROOT/pharo" "$TEST_ROOT/home"
ln -s "$SOURCE_DIR" "$TEST_ROOT/src"
ln -s "$PWD/prompts" "$TEST_ROOT/prompts"
mkdir -p "$PWD/pharo/pharo-local"
ln -s "$PWD/pharo/pharo-local" "$TEST_ROOT/pharo/pharo-local"

TEST_IMAGE="$TEST_ROOT/pharo/AgentTest.image"
TEST_CHANGES="${TEST_IMAGE%.image}.changes"
SOURCES=$(find pharo -maxdepth 1 -name '*.sources' -print -quit)

run_dependency_loader() {
  local status log
  log="$TEST_ROOT/dependency-load.log"
  set +e
  env HOME="$TEST_ROOT/home" "$VM" --headless "$TEST_IMAGE" st scripts/load-all.st 2>&1 | tee "$log"
  status=${PIPESTATUS[0]}
  set -e
  if [ "$status" -ne 0 ]; then
    echo "Dependency loading failed before project packages or SUnit could run."
    return "$status"
  fi
  ./scripts/check-warning-policy.sh --full "$log" | tee -a "$log"
}

run_sunit() {
  local status
  set +e
  env HOME="$TEST_ROOT/home" "$VM" --headless "$TEST_IMAGE" st scripts/run-tests.st 2>&1 | tee "$TEST_ROOT/sunit.log"
  status=${PIPESTATUS[0]}
  set -e
  return "$status"
}

cleanup() {
  if [ "${AGENT_KEEP_TEST_ROOT:-}" = "1" ]; then
    echo "Retained native test root: $TEST_ROOT"
  else
    rm -rf "$TEST_ROOT"
  fi
}
trap cleanup EXIT

cp "$PRISTINE" "$TEST_IMAGE"
cp "${PRISTINE%.image}.changes" "$TEST_CHANGES"
if [ -n "${SOURCES:-}" ]; then
  cp "$SOURCES" "$TEST_ROOT/pharo/"
fi

run_dependency_loader
run_sunit

if [ -n "${AGENT_UPDATE_MANIFEST:-}" ]; then
  env HOME="$TEST_ROOT/home" AGENT_UPDATE_MANIFEST="$AGENT_UPDATE_MANIFEST" \
    "$VM" --headless "$TEST_IMAGE" st scripts/verify-update-preflight.st
fi
