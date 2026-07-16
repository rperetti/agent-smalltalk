#!/bin/bash
# Build a fresh Agent image from source.
#
# Usage:
#   ./build.sh [core|all] [--output pharo/Agent.image] [--verify|--no-verify]
#
# Environment overrides:
#   PHARO_VM=/path/to/Pharo
#   PHARO_PRISTINE=/path/to/Pharo13...image
#
# This is the factory-reset path: it creates a brand-new image from the
# pristine Pharo image and the Tonel sources. Use update.sh for a living image
# whose widgets, facts, generated classes, and tools should survive.
set -euo pipefail
cd "$(dirname "$0")"

usage() {
  cat <<'EOF'
Usage: ./build.sh [core|all] [options]

Build a fresh Agent image from the pristine Pharo image.

Arguments:
  core                    Load Core only: gateway/sandbox/tests, no Bloc UI.
  all                     Load the full default image (default).

Options:
  -o, --output PATH       Output image path (default: pharo/Agent.image).
  --verify               Run scripts/run-tests.st before replacing output.
                          This is the default.
  --no-verify            Skip the SUnit verification pass.
  --no-backup            Do not back up an existing output image first.
  -h, --help             Show this help.

Environment:
  PHARO_VM                Pharo VM executable to use.
  PHARO_PRISTINE         Pristine Pharo .image to copy from.
EOF
}

GROUP="all"
OUTPUT="pharo/Agent.image"
VERIFY=1
BACKUP=1

while [ "$#" -gt 0 ]; do
  case "$1" in
    core|all)
      GROUP="$1"
      shift
      ;;
    -o|--output)
      [ "$#" -ge 2 ] || { echo "Missing value for $1"; exit 1; }
      OUTPUT="$2"
      shift 2
      ;;
    --verify)
      VERIFY=1
      shift
      ;;
    --no-verify)
      VERIFY=0
      shift
      ;;
    --no-backup)
      BACKUP=0
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

case "$GROUP" in
  core) LOAD_SCRIPT="scripts/load-core.st" ;;
  all) LOAD_SCRIPT="scripts/load-all.st" ;;
  *) echo "Unsupported build group: $GROUP"; exit 1 ;;
esac

case "$OUTPUT" in
  *.image) ;;
  *) echo "Output path must end in .image: $OUTPUT"; exit 1 ;;
esac

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

if [ -n "${PHARO_PRISTINE:-}" ]; then
  PRISTINE="$PHARO_PRISTINE"
else
  PRISTINE=$(find pharo -maxdepth 1 -name 'Pharo*-64bit-*.image' -print | sort | head -1)
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

if [ "$OUTPUT" = "pharo/Agent.image" ] && pgrep -f "Agent.image" >/dev/null 2>&1; then
  echo "A process using Agent.image appears to be running."
  echo "Quit it before replacing pharo/Agent.image, or pass --output PATH."
  exit 1
fi

OUTPUT_DIR=$(dirname "$OUTPUT")
OUTPUT_BASE=$(basename "$OUTPUT")
OUTPUT_CHANGES="${OUTPUT%.image}.changes"
mkdir -p "$OUTPUT_DIR"

BUILD_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/agent-smalltalk-build.XXXXXX")
BUILD_HOME="$BUILD_ROOT/home"
BUILD_IMAGE="$BUILD_ROOT/pharo/$OUTPUT_BASE"
BUILD_CHANGES="${BUILD_IMAGE%.image}.changes"
mkdir -p "$BUILD_HOME" "$BUILD_ROOT/pharo"
ln -s "$PWD/src" "$BUILD_ROOT/src"
ln -s "$PWD/prompts" "$BUILD_ROOT/prompts"
mkdir -p "$PWD/pharo/pharo-local"
ln -s "$PWD/pharo/pharo-local" "$BUILD_ROOT/pharo/pharo-local"

cleanup() {
  if [ -n "${BUILD_ROOT:-}" ]; then
    rm -rf "$BUILD_ROOT"
  fi
}
trap cleanup EXIT

run_dependency_loader() {
  local status log
  log="$BUILD_ROOT/dependency-load.log"
  set +e
  HOME="$BUILD_HOME" "$VM" --headless "$BUILD_IMAGE" st "$LOAD_SCRIPT" 2>&1 | tee "$log"
  status=${PIPESTATUS[0]}
  set -e
  if [ "$status" -ne 0 ]; then
    echo "Dependency loading failed before project packages or SUnit could run."
    return "$status"
  fi
  if [ "$GROUP" = "all" ]; then
    ./scripts/check-warning-policy.sh --full "$log" | tee -a "$log"
  else
    ./scripts/check-warning-policy.sh "$log" | tee -a "$log"
  fi
}

SOURCES=$(find "$(dirname "$PRISTINE")" -maxdepth 1 -name '*.sources' -print | sort | head -1)
if [ -n "${SOURCES:-}" ]; then
  cp "$SOURCES" "$BUILD_ROOT/pharo/"
  OUTPUT_DIR_ABS=$(cd "$OUTPUT_DIR" && pwd -P)
  SOURCES_DIR_ABS=$(cd "$(dirname "$SOURCES")" && pwd -P)
  if [ "$SOURCES_DIR_ABS" != "$OUTPUT_DIR_ABS" ]; then
    cp "$SOURCES" "$OUTPUT_DIR/"
  fi
else
  echo "Warning: no .sources file found next to $PRISTINE; source browsing may be degraded."
fi

cp "$PRISTINE" "$BUILD_IMAGE"
cp "$PRISTINE_CHANGES" "$BUILD_CHANGES"

echo "Building fresh image:"
echo "  group:    $GROUP"
echo "  vm:       $VM"
echo "  pristine: $PRISTINE"
echo "  output:   $OUTPUT"
echo "  staging:  $BUILD_ROOT"
echo "  home:     $BUILD_HOME"

run_dependency_loader

if [ "$VERIFY" -eq 1 ]; then
  echo "Verifying built image with SUnit..."
  HOME="$BUILD_HOME" "$VM" --headless "$BUILD_IMAGE" st scripts/run-tests.st
fi

if [ "$BACKUP" -eq 1 ] && [ -f "$OUTPUT" ]; then
  mkdir -p pharo/backups
  BACKUP_IMAGE="pharo/backups/pre-build-$(date +%s).image"
  cp "$OUTPUT" "$BACKUP_IMAGE"
  if [ -f "$OUTPUT_CHANGES" ]; then
    cp "$OUTPUT_CHANGES" "${BACKUP_IMAGE%.image}.changes"
  fi
  echo "Backed up existing image to $BACKUP_IMAGE"
fi

mv "$BUILD_IMAGE" "$OUTPUT"
mv "$BUILD_CHANGES" "$OUTPUT_CHANGES"

echo "Built $OUTPUT (group: $GROUP, verified: $VERIFY)"
