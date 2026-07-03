# agent-smalltalk

A living agentic environment: an LLM writes Pharo Smalltalk that is compiled
live into a running image, materializing widgets on a spatial canvas.
See [original_spec.md](original_spec.md) for the vision and
[demo_spec.md](demo_spec.md) for the first demo scope.

## Setup

1. Pharo 13 image + VM live in `pharo/` (gitignored). To fetch them:
   download `pharoImage-arm64.zip` and `pharo-vm-Darwin-arm64-stable.zip`
   from https://files.pharo.org/get-files/130/ and unzip into `pharo/`
   (VM into `pharo/vm/`).
2. `export ANTHROPIC_API_KEY=sk-ant-...` (needs API credits).

## Commands

| command | what it does |
|---|---|
| `./build.sh` | build `pharo/Agent.image` from `src/` (loads Bloc; `./build.sh core` skips UI) |
| `./test.sh` | run the SUnit suite headless |
| `./run.sh` | open the Agent canvas (Cmd/Ctrl+Enter summons the spotlight bar) |

Headless one-shot ask:

```bash
./pharo/vm/Pharo.app/Contents/MacOS/Pharo --headless pharo/Agent.image \
  eval "AgentGateway ask: 'make me a counter widget'"
```

## Layout

- `src/` — Tonel packages (Core: gateway + sandbox; UI: canvas, widget, spotlight; Tests)
- `prompts/system.md` — the crib sheet: the system prompt that teaches the model
  Pharo/Bloc and the AgentWidget contract. Treat it as code.
- `scripts/` — image build/test scripts run by the shell wrappers
- `logs/gateway.log` (gitignored) — append-only transcript of every agent
  request: loop events, evaluated code, results/errors, and full HTTP
  request/response JSON. In-image: `AgentGateway last log` for the most
  recent run. The API key is never logged.
