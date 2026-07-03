# agent-smalltalk

A living agentic environment: an LLM writes Pharo Smalltalk that is compiled
live into a running image, materializing widgets on a spatial canvas.
See [docs/vision.md](docs/vision.md) for the vision,
[docs/system_spec.md](docs/system_spec.md) for what is built and working
today, [docs/phase3_spec.md](docs/phase3_spec.md) for the next phase
(spatial context), and [docs/ideas.md](docs/ideas.md) for the parking lot.

## Setup

1. Pharo 13 image + VM live in `pharo/` (gitignored). To fetch them:
   download `pharoImage-arm64.zip` and `pharo-vm-Darwin-arm64-stable.zip`
   from https://files.pharo.org/get-files/130/ and unzip into `pharo/`
   (VM into `pharo/vm/`).
2. `export ANTHROPIC_API_KEY=sk-ant-...` (needs API credits).

## Commands

| command | what it does |
|---|---|
| `./build.sh` | build a FRESH `pharo/Agent.image` from `src/` — destroys existing widgets/facts |
| `./update.sh` | reload tooling from `src/` into the LIVING image — world preserved; use this one |
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
