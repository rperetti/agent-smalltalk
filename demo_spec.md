# Demo 1 Specification: Summon a Living Widget

## Goal

Prove the core thesis of the Living Agentic Environment ([original_spec.md](original_spec.md)) with the smallest possible slice:

> The user summons a floating prompt bar, types a request in plain English, and a working, stateful widget appears on a canvas — built by an LLM writing Smalltalk code that is compiled live into the running image, and still there (still working) after the image is saved and reopened.

If this demo works, everything else in the original spec is an extension of it. If it doesn't, nothing else matters.

## What the demo proves

1. **Live compilation loop**: an external LLM can reliably produce Pharo code that is compiled and executed in the running image, without restarts.
2. **Self-repair**: when generated code fails, the error feeds back to the model and it fixes its own code — the loop is agentic, not one-shot.
3. **Persistence for free**: widgets and their state survive `Smalltalk snapshot` because they are ordinary live objects in the image.
4. **The interaction model**: spotlight bar → widget under cursor. No chat window.

## Explicit non-goals (deferred, not rejected)

- Spatial gardener features: semantic clustering, camera wormholes, breadcrumbs.
- Lasso-select context management (the canvas will be small enough not to need it yet).
- Direct manipulation rewriting source code (drag/resize may update object *state*, never source).
- Visual programming by drawing connections between widgets.
- Multiplayer.
- PDF / Excel / email ingestion use cases.

## Architecture

Four components, all inside one Pharo 12+ image:

### 1. `AgentGateway` — the HTTP bridge

- Talks to the Anthropic Messages API (Claude) using Zinc HTTP.
- API key read from an environment variable or a one-time settings dialog; never hardcoded, never saved in the repo.
- Implements the **tool-use loop**, not one-shot generation: the request declares an `evaluate_smalltalk` tool; the model calls it, the gateway executes the code and returns the printString of the result — or the full error description — as the tool result; the model iterates until it declares success or hits the iteration cap (default: 8 rounds).
- This replaces the original spec's "Code Extractor". There is no response parsing or markdown stripping; code arrives as structured tool-call input.

### 2. `AgentSandbox` — the evaluator with a safety story

- Wraps `Compiler evaluate:` (well, `OpalCompiler`) with:
  - **Error capture**: syntax errors and runtime exceptions (including doesNotUnderstand) are caught and serialized into a readable report for the tool result — selector, receiver class, and stack summary — so the model can repair.
  - **Timeout**: evaluation runs in a worker process killed after N seconds (default 10) to survive accidental infinite loops.
  - **Snapshot-before-mutate**: before each user request begins, the image is saved to a rotating backup (`agent-backup-N.image`, keep last 5). Crude, but it makes "the LLM corrupted my world" recoverable from day one.
- Not attempted in v1: true sandboxing/capability restriction. The model can touch anything in the image. Acceptable for a single-user prototype; revisit before anything multi-user.

### 3. `AgentCanvas` — the minimal Bloc surface

- A single fullscreen `BlElement` scene: pannable, zoomable, plain background.
- Widgets are `BlElement` subclasses placed at the cursor position when created.
- Widgets are draggable (position is object state — no source rewriting).
- A small affordance on each widget (right-click or badge) shows **the source that built it**, in a Pharo browser. The generated code must be inspectable — this is the "knowledge = code" tenet made visible.

### 4. `AgentSpotlight` — the prompt bar

- Global keyboard shortcut (Cmd+Return inside the Pharo window is fine for v1; OS-global can wait) opens a floating single-line text input.
- Enter sends the request to `AgentGateway`; the bar shows a minimal status line while the loop runs ("thinking… / evaluating… / repairing (attempt 3)…") so failures are legible.
- On success the bar disappears and the widget exists. On failure after the iteration cap, it shows the last error and keeps the transcript of attempts inspectable.

## Context mapping (v1 strategy)

Do not serialize the image. The system prompt contains a **hand-written crib sheet**, and per-request context is tiny:

1. **Static crib (system prompt)**: Pharo syntax reminders, the exact Bloc APIs we bless for widget construction (element creation, layout, text, click handlers, geometry), the `AgentWidget` base-class contract, and 2–3 few-shot examples of complete, correct widgets. This directly attacks the "LLMs are weak at Pharo/Bloc" risk — the model builds from the crib, not from its training-data guesses.
2. **Dynamic context (per request)**: the list of existing widgets on the canvas — class name, label, position, and a one-line self-description each. Nothing more.

The crib sheet is expected to be the highest-leverage artifact in the whole demo and will be iterated on constantly. Treat it as code: it lives in the repo (`prompts/system.md`) and is loaded by the image, not embedded in a method string.

## The `AgentWidget` contract

Every generated widget subclasses `AgentWidget` (a thin `BlElement` subclass we write by hand), which provides:

- Registration on the canvas and placement at summon position.
- Drag behavior and the "show my source" affordance.
- A `describe` method (returns the one-liner used in dynamic context).
- Serialization by simply *existing* — no persistence code needed; the image is the database.

Constraining the model to fill in a known contract, rather than inventing structure, is the second big reliability lever after the crib sheet.

## Demo script (acceptance criteria)

The demo is done when this exact sequence works reliably (target: 8 of 10 cold runs succeed without human intervention):

1. Open the image. Press the shortcut. Type: **"make me a counter with + and − buttons"**. A working counter widget appears under the cursor. Click + three times; it reads 3.
2. Press the shortcut. Type: **"make a to-do list where I can add items and check them off"**. It appears and works alongside the counter.
3. Drag both widgets to new positions.
4. **Save the image and quit. Reopen.** Both widgets are where they were left; the counter still reads 3; the to-do items are intact. Press + — it still works.
5. Right-click the counter, choose "source" — a browser opens on the generated class.
6. Press the shortcut. Type: **"make the counter count by 10"**. The agent locates the existing widget class (from dynamic context), recompiles the relevant method live, and the running counter — without being recreated — now increments by 10. *This is the live-modification money shot.*
7. Failure-path check: type a request whose first generation attempt fails (this will happen naturally; if not, temporarily poison the crib). Observe the status line show a repair round and the widget still arrive.

## Build order

1. `AgentGateway` with tool-use loop, driven from a workspace (no UI) — get "prompt in, evaluated code out, errors repaired" working headless first.
2. `AgentSandbox`: error capture, timeout, image backups.
3. `AgentWidget` + `AgentCanvas`: hand-write the counter widget first to prove the contract, then delete it and make the model produce it.
4. Crib sheet iteration until the counter and to-do requests pass cold.
5. `AgentSpotlight` and the status line.
6. Live-modification flow (step 6 of the demo script).

## Key risks carried into this demo

- **Model quality on Bloc APIs** — mitigated by the crib sheet and the narrow `AgentWidget` contract; measured by the 8-of-10 acceptance bar.
- **Bloc maturity** — if Bloc friction dominates, fall back to Toplo (Bloc-based widget set) or, worst case, Morphic for v1; the architecture doesn't care.
- **Latency** — a multi-round repair loop over HTTP may take 30–60s per widget. Acceptable for the demo; the status line keeps it honest. Prompt caching of the crib sheet is the first optimization.
