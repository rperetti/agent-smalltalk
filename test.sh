#!/bin/bash
# Run the SUnit suite headless against pharo/Agent.image.
set -euo pipefail
cd "$(dirname "$0")"
exec pharo/vm/Pharo.app/Contents/MacOS/Pharo --headless pharo/Agent.image st scripts/run-tests.st
