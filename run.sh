#!/bin/bash
# Open the Agent canvas UI. Requires ANTHROPIC_API_KEY in the environment.
set -euo pipefail
cd "$(dirname "$0")"
exec pharo/vm/Pharo.app/Contents/MacOS/Pharo pharo/Agent.image eval --no-quit "AgentCanvas open"
