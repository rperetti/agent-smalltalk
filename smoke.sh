#!/bin/bash
# Run one smoke script in a fresh, disposable full image. Provider-backed
# checks require an explicit flag so the normal verification path never spends
# money or relies on a non-deterministic model response.
set -euo pipefail
cd "$(dirname "$0")"

usage() {
  cat <<'EOF'
Usage:
  ./smoke.sh <automations|provider-syntax>
  ./smoke.sh --provider <fact-retrieval|fact-baseline|context-adversarial|prompt-cache|fact-widget|widget|modify|textfield|facts|tools|selection|reactive|prompt-contract>

Each run loads a fresh disposable image. --provider requires ANTHROPIC_API_KEY
and records structured evidence in logs/provider-evaluations.jsonl.
EOF
}

[ "$#" -ge 1 ] || { usage; exit 1; }

MODE="deterministic"
if [ "$1" = "--provider" ]; then
  [ "$#" -eq 2 ] || { usage; exit 1; }
  MODE="provider"
  NAME="$2"
else
  [ "$#" -eq 1 ] || { usage; exit 1; }
  NAME="$1"
fi

case "$NAME" in
  automations)
    [ "$MODE" = "deterministic" ] || { echo "automations is deterministic; omit --provider"; exit 1; }
    SCRIPT="scripts/smoke-automations.st"
    ;;
  provider-syntax)
    [ "$MODE" = "deterministic" ] || { echo "provider-syntax is deterministic; omit --provider"; exit 1; }
    SCRIPT="scripts/verify-provider-smoke-syntax.st"
    ;;
  fact-retrieval|fact-baseline|context-adversarial|prompt-cache|fact-widget|widget|modify|textfield|facts|tools|selection|reactive|prompt-contract)
    [ "$MODE" = "provider" ] || { echo "$NAME is provider-backed; pass --provider explicitly"; exit 1; }
    SCRIPT="scripts/smoke-$NAME.st"
    ;;
  *)
    echo "Unknown smoke: $NAME"
    usage
    exit 1
    ;;
esac

if [ "$MODE" = "provider" ] && [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  echo "ANTHROPIC_API_KEY is required for provider evaluations."
  exit 1
fi

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

PRISTINE_CHANGES="${PRISTINE%.image}.changes"
[ -f "$PRISTINE_CHANGES" ] || {
  echo "Missing pristine changes file: $PRISTINE_CHANGES"
  exit 1
}

SMOKE_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/agent-smalltalk-smoke.XXXXXX")
cleanup() {
  # AgentEvaluation writes relative to the disposable image. Preserve paid
  # evidence before that image is removed, including evidence from a failing
  # semantic gate.
  if [ "$MODE" = "provider" ] && [ -f "$SMOKE_ROOT/logs/provider-evaluations.jsonl" ]; then
    mkdir -p logs
    cat "$SMOKE_ROOT/logs/provider-evaluations.jsonl" >> logs/provider-evaluations.jsonl
  fi
  rm -rf "$SMOKE_ROOT"
}
trap cleanup EXIT

mkdir -p "$SMOKE_ROOT/pharo" "$SMOKE_ROOT/home"
ln -s "$PWD/src" "$SMOKE_ROOT/src"
ln -s "$PWD/prompts" "$SMOKE_ROOT/prompts"
ln -s "$PWD/scripts" "$SMOKE_ROOT/scripts"
mkdir -p "$PWD/pharo/pharo-local"
ln -s "$PWD/pharo/pharo-local" "$SMOKE_ROOT/pharo/pharo-local"

SMOKE_IMAGE="$SMOKE_ROOT/pharo/AgentSmoke.image"
cp "$PRISTINE" "$SMOKE_IMAGE"
cp "$PRISTINE_CHANGES" "${SMOKE_IMAGE%.image}.changes"
SOURCES=$(find pharo -maxdepth 1 -name '*.sources' -print -quit)
if [ -n "${SOURCES:-}" ]; then
  cp "$SOURCES" "$SMOKE_ROOT/pharo/"
fi

echo "Running $MODE smoke: $NAME"
env HOME="$SMOKE_ROOT/home" "$VM" --headless "$SMOKE_IMAGE" st scripts/load-all.st
env HOME="$SMOKE_ROOT/home" "$VM" --headless "$SMOKE_IMAGE" st "$SCRIPT"
