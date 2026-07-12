# agent-smalltalk

A living agentic environment: an LLM writes Pharo Smalltalk that is compiled
live into a running image, materializing widgets on a spatial canvas.
Start with the [documentation map](docs/README.md): the
[vision](docs/vision.md) describes the north star, the
[system specification](docs/system_spec.md) records what works today, and the
[backlog](docs/backlog.md) is the ordered register of actionable work.

Project planning is file-based and lives under `docs/`, not tracked in GitHub
Issues. Issues and discussions are still welcome — for bug reports, feature
requests, and ideas — and get triaged into the file-based backlog. See
[CONTRIBUTING.md](CONTRIBUTING.md) for how to contribute.

## Demo

<!-- TODO(AS-23): embed a canvas screenshot once we agree on a representative
     canvas to show. Suggested path: docs/assets/canvas.png -->

_A canvas screenshot is coming._ Until then, the quickest demonstration is a
headless one-shot that has the agent write and place a widget (after
[Setup](#setup), with `ANTHROPIC_API_KEY` exported):

```bash
./pharo/vm/Pharo.app/Contents/MacOS/Pharo --headless pharo/Agent.image \
  eval "AgentGateway ask: 'make me a counter widget'"
```

Or run `./run.sh`, press Cmd/Ctrl+Enter to open the Spotlight bar, and ask for
anything — a fact, a tool, or a widget.

## Motivation

Agents reach today's operating systems through APIs, file formats, and
screen-scraping — like working in a heavy pair of mittens. Everything is siloed.
A wave of capable open-source agents now meets that world where it is —
operating our existing browsers, apps, and tools — like OpenClaw and Nous
Research's Hermes. This project makes a different bet: build the environment
around the agent instead of bolting the agent onto the environment.

Smalltalk is the model. It isn't just a language; it's a live system you work
inside, modifying it while it runs. Applying that to an agent turns a stateless
chatbot into a shared, editable workspace.

**The vision, and where it stands today:**

* **Knowledge is code** *(working today).* A fact and a tool are the same kind of
  thing. A note about your coffee is an object; a script that orders that coffee
  is also an object. They live in one environment, so the agent links them with
  no database. Facts are editable objects on the canvas, and the agent writes its
  own reusable tools the same way.

* **An evolving environment** *(working today).* The agent starts generic and
  specializes as it works — writing reusable tools instead of re-deriving them,
  and attaching visible, pausable schedules that run saved Smalltalk without
  another model call. You shape it by talking to it, correcting it, and sharing
  your digital life with it.

* **The spatial canvas** *(partly built; mostly direction).* The canvas is a
  shared space where you and the agent both place and move objects, and you can
  lasso a cluster to hand the agent exactly the context you mean. The goal from
  here: an agent that groups related things by proximity, so keeping the
  workspace tidy isn't one more thing you have to do.

This is an experiment — push the idea to its limits and find where it breaks. The
goal is a useful place for a human and an agent to expand what they know and can
do together. For what runs today versus what's still ahead, see
[what's built](docs/system_spec.md) and [the vision](docs/vision.md).


## ⚠️ Heads up — this is an experiment, with no guardrails

agent-smalltalk is a research prototype shared for the curious, **not a polished
or production-ready product**. Expect rough edges, bugs, and breaking changes;
there are no promises of stability or support.

Most importantly, **there are no guardrails, by design.** The whole premise is
an unconstrained living environment, so:

- The agent writes Smalltalk and **executes it immediately** in the running
  image, with full authority — there is *no sandbox*. It can run arbitrary
  code, make network requests, and touch anything in the image and, through
  it, your machine. Run it somewhere you're comfortable handing a coding agent
  the keys.
- Everything on the canvas — including any facts you tell it — is **sent to the
  Anthropic API on every request**. Don't put secrets or sensitive personal
  data in it.
- It calls the Anthropic API, so **it costs money** per request.

Treat it as a toy to explore, not a tool to depend on. No warranty; use at your
own risk — and have fun with it. The current authority boundaries, data flows,
and known exposures are documented in the [security and trust
model](docs/security.md).

## Setup

**Supported platform.** Development happens on **macOS on Apple Silicon
(arm64) with Pharo 13**, and the `run.sh`/`update.sh` wrappers currently assume
the macOS Pharo app bundle. Other platforms are not yet a supported path: on
Linux/Windows or Intel macs you would supply your own VM and image via the
`PHARO_VM` / `PHARO_PRISTINE` overrides (see
[docs/operations.md](docs/operations.md#prerequisites)), and the GUI wrappers
would need adapting.

**Disk and time.** A fresh full build takes roughly **1.5 minutes** and
produces a ~95 MiB image plus a ~13 MiB `.changes` file; the shared dependency
cache adds ~90 MiB. Budget on the order of **300–400 MiB** for a working
checkout including the downloaded VM. (Measured 2026-07-11; see the
[dependency-load table](docs/operations.md#dependency-load-measurement).)

1. Pharo 13 image + VM live in `pharo/` (gitignored). To fetch them:
   download `pharoImage-arm64.zip` and `pharo-vm-Darwin-arm64-stable.zip`
   from https://files.pharo.org/get-files/130/ and unzip into `pharo/`
   (VM into `pharo/vm/`).
2. `export ANTHROPIC_API_KEY=sk-ant-...` (needs API credits).

## Commands

| command | what it does |
|---|---|
| `./build.sh` | build a FRESH verified `pharo/Agent.image` from `src/`; backs up/replaces any existing world only after the new image loads and tests pass |
| `./update.sh` | reload tooling from `src/` into the LIVING image — world preserved; use this one |
| `./test.sh` | build a disposable clean image and run SUnit; never opens `Agent.image` |
| `./verify-all.sh` | run every deterministic release gate: SUnit, automation smoke, and paid-smoke syntax checks |
| `./evaluate.sh` | explicitly run paid model evaluations in fresh images; requires `ANTHROPIC_API_KEY` and writes JSON evidence |
| `./run.sh` | open the Agent canvas (Cmd/Ctrl+Enter summons the Spotlight bar) |

`build.sh` accepts `core`/`all`, `--output PATH`, `--no-verify`,
`--no-backup`, and the `PHARO_VM` / `PHARO_PRISTINE` environment overrides.
It runs Pharo with an isolated temporary `HOME`, so builds do not mutate your
global Pharo preferences. Use `--output /tmp/Some.image` when you want to
test a fresh build without replacing the living `pharo/Agent.image`.
For the state model, update paths, backup limitations, smoke scripts, logs, and
recovery procedures, see [docs/operations.md](docs/operations.md). The headless
one-shot request is shown in [Demo](#demo) above.

## Architecture overview

A single request flows through a small number of parts:

- **Spotlight** — the input bar (summoned with Cmd/Ctrl+Enter) where you type a
  request to the agent.
- **Gateway** (`AgentGateway`) — sends your request, plus everything currently
  on the canvas, to the Anthropic API, and runs the model's tool-use loop.
- **Sandbox** (`AgentSandbox`) — compiles the Smalltalk the model writes and
  executes it *live* in the running image. There is no isolation boundary; this
  is the "no guardrails" part.
- **Canvas** (`AgentCanvas`) — the spatial surface where the results live:
  **widgets** (interactive UI the agent built), **facts** (editable knowledge
  objects), and **tool cards** (reusable Smalltalk the agent saved to call again
  without another model request). Automations can attach visible, pausable
  schedules that re-run saved code on their own.

Because facts, tools, and widgets are all just objects in one running image, the
agent links knowledge and behavior fluidly with no external database. Everything
persists in `pharo/Agent.image`; the reproducible platform source lives in
`src/`. That source-vs-image distinction is the most important thing to
understand before contributing — see [CONTRIBUTING.md](CONTRIBUTING.md) and the
[state model](docs/operations.md#state-model).

## Layout

- `src/` — Tonel packages (Core: gateway, sandbox, tools, automation scheduler;
  UI: canvas, widgets, and the *routines shelf* — the bottom-center tray of
  pausable automations; Tests)
- `docs/` — vision, as-built specification, ordered backlog, ideas incubator,
  security/trust model, operations guide, postponed designs, and architectural
  decisions
- `prompts/system.md` — the base prompt that teaches the model
  Pharo/Bloc and the AgentWidget contract. Treat it as code.
- `scripts/` — image build/test scripts run by the shell wrappers
- `logs/gateway.log` (gitignored) — append-only transcript of every agent
  request: loop events, evaluated code, results/errors, and full HTTP
  request/response JSON. In-image: `AgentGateway last log` for the most
  recent run. The API key is never logged.

Bloc, Toplo, and their transitive dependencies are pinned to exact revisions.
The normal full build loads only AgentSmalltalk's declared production UI
closure; upstream tests, examples, demos, and developer tools are excluded.
They remain available through the explicit disposable-image path documented in
`docs/operations.md`. Testing currently runs on the user's machine via
`./test.sh`; hosted GitHub CI is deferred.

## Contributing

Contributions are welcome — start with [CONTRIBUTING.md](CONTRIBUTING.md), which
explains the `src/`-versus-image-state distinction, the test and build habits,
and the documentation responsibilities that keep the living environment
coherent. Planning is file-based under `docs/`; see the
[documentation map](docs/README.md).

## License

Released under the [MIT License](LICENSE).

## Acknowledgments

This project is an experiment in human–agent collaboration, and it was built
the same way. The idea and direction are Rodrigo Peretti's; the implementation (so far)
was a genuine collaboration with several AI models — **Claude Opus 4.8** and
**Claude Fable 5** (Anthropic), **Gemini Pro** (Google), and **OpenAI Codex
(GPT-5)** — pairing on the design, the code, and the many debugging sessions
along the way.

So the "we" throughout this README is literal: a project about a human and an
agent expanding their capabilities together, made by a human and several
agents doing exactly that. The commit history carries `Co-Authored-By`
trailers as a record of the partnership.
