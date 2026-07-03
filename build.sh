#!/bin/bash
# Build the Agent image from source. Usage: ./build.sh [core|all]
# Starts from a fresh copy of the pristine Pharo image, loads the code, saves.
set -euo pipefail
cd "$(dirname "$0")"

GROUP="${1:-all}"
VM="pharo/vm/Pharo.app/Contents/MacOS/Pharo"
PRISTINE=$(ls pharo/Pharo*-64bit-*.image | head -1)

cp "$PRISTINE" pharo/Agent.image
cp "${PRISTINE%.image}.changes" pharo/Agent.changes

"$VM" --headless pharo/Agent.image st "scripts/load-${GROUP}.st"
echo "Built pharo/Agent.image (group: $GROUP)"
