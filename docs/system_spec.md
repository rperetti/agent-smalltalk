# System Specification (as built)

What the living agentic environment does **today**. The long-term vision lives
in [original_spec.md](original_spec.md). This document is kept in sync with the
code; when behavior changes, change this file in the same commit.

*Last updated: 2026-07-03 (phase 2: knowledge on the canvas).*

## One-paragraph summary

A Pharo 13 image where an LLM (Anthropic `claude-sonnet-5`) writes Smalltalk
that is compiled **live** into the running system. The user summons a floating
prompt bar over a spatial canvas, types a request in English, and a working,
stateful widget appears — built, tested, and repaired by the model through an
agentic tool-use loop. Widgets and their state survive image save/reopen: the
image is the database.

## Components

All code is in `src/` as Tonel packages, loaded by `BaselineOfAgentSmalltalk`
(groups: `Core` without UI/Bloc; `default` with everything). Dependencies:
Bloc (graphics scene graph) and Toplo (widget set on Bloc), both from
pharo-graphics on GitHub.

### AgentGateway (Core)

The bridge to the Anthropic Messages API and the owner of the agentic loop.

- Model `claude-sonnet-5`, max 8192 output tokens, up to **20 tool rounds**
  per request; API key from `ANTHROPIC_API_KEY` (never logged, never stored).
- Declares two tools to the model:
  - **`evaluate_smalltalk`** — code is evaluated by `AgentSandbox`; the tool
    result is `RESULT: <printString>` or `ERROR: <report>`, and the model
    iterates on errors (self-repair).
  - **`search_image`** — structured image exploration via `AgentImageSearch`:
    `find_classes` (name fragment), `find_selectors` (class + fragment),
    `method_source` (class + selector, `'Foo class'` for class side).
- System prompt = the crib sheet (`prompts/system.md`) + the canvas context
  in two sections: `## Known facts` (all stickies) and `## Widgets on the
  canvas` (class, position, `describe`).
- Status callbacks (`statusBlock:`) drive the spotlight's status line:
  `thinking... / evaluating... / working (round N of 20)...`.
- Transcript: every event and the **full HTTP request/response JSON** are
  appended to `logs/gateway.log`; `AgentGateway last log` gives in-image
  access to the most recent run.
- Entry points: `AgentGateway ask: 'request'` (headless or programmatic);
  the spotlight uses an instance with a status block.

### AgentSandbox (Core)

Evaluates model-generated code with guardrails:

- Normalizes LF → CR before compiling (JSON delivers LF; Pharo source is CR).
- Catches all errors and answers a report: class, message text, top stack
  frames — plus, for `doesNotUnderstand:`, up to 8 **similar selectors the
  receiver does understand**.
- 10-second evaluation timeout (survives infinite loops).
- Before each gateway request: copies the image file to `pharo/backups/`
  (rotating, keeps 5) so a corrupted image is recoverable.
- Not sandboxed in the capability sense: the model can touch anything in the
  image. Accepted risk for a single-user prototype.

### AgentCanvas (UI)

Singleton owning the Bloc space (`AgentCanvas open`, 1280×840, `ToBeeTheme`).

- Widgets live on a content element; `addWidget:` defers to the UI thread via
  `enqueueTask:` when the space is open.
- **Headless mode**: with no space open, widgets attach to a detached content
  element, so the full generation loop runs (and is tested) without a display.
- `contextDescription` renders the widget list for the system prompt.
- Cmd/Ctrl+Enter summons the spotlight.
- Not yet spatial beyond free placement: no pan, no zoom, no lasso.

### AgentWidget (UI)

The contract every generated widget subclasses:

- A white rounded 240×160 card, vertical linear layout, 12px padding,
  draggable (`BlPullHandler`), right-click opens a code browser on the
  generated class ("knowledge = code", made visible).
- `describe` — one-line self-description including current state; this is how
  the model recognizes existing widgets in later requests.
- Class side: `summonAt: aPoint` (create + place + register) and
  `defineNamed:slots:` — the **blessed class-creation helper** that insulates
  the model from Pharo class-builder API drift. Generated classes go to the
  `AgentSmalltalk-Generated` package.

### AgentFact (UI)

Sticky-note memory ([phase2_spec.md](phase2_spec.md)): a small pale-yellow
widget holding one durable fact. The body is editable in place (`ToAlbum` —
editing the text IS editing the memory); the `x` button deletes (forgetting
is a physical act). An optional key gives identity: `AgentFact key: #city
body: '...'` creates **or updates** — one sticky per key, ever. New stickies
pile near the top-left. Facts are instances of this hand-written class,
never generated classes. Capture is implicit and loud: the crib instructs
the model to save durable facts stated even in passing, and the sticky
visibly appearing on the canvas is the announcement.

### AgentSpotlight (UI)

The floating prompt bar: a wrapping multi-line `ToAlbum` editor (cursor,
selection, clipboard; grows vertically with content) plus a `ToLabel` status
line. Enter submits and Esc closes via capture-phase event filters (they win
over the editor). The gateway runs in a forked process; UI updates are
enqueued onto the space pulse.

### The crib sheet (`prompts/system.md`)

The system prompt that teaches the model the environment. **Treat it as code**
— it is the highest-leverage artifact in the system. It covers: the tool
protocol and workflow (define class → compile methods → test headless →
`summonAt:`), the AgentWidget contract, the blessed Toplo vocabulary
(`ToLabel`, `ToButton clickAction:`, `ToTextField`, `ToAlbum`, `ToCheckbox
checkAction:`, `ToProgressBar valueInPercentage:`), raw-Bloc recipes for
custom visuals, live-modification guidance (recompile methods, instances
update instantly), the fact-capture policy (implicit, keyed, update-don't-
duplicate, use silently, never secrets), Pharo syntax pitfalls, and when to
reach for `search_image` instead of reflection snippets. Every blessed
selector has been verified against the loaded packages.

## Verified capabilities (all cold runs against the live API)

- **Generate**: "make me a counter with + and − buttons" → class defined,
  methods compiled, logic tested headless, widget summoned. Includes observed
  self-repair (model added a missing accessor after reading the error).
- **Modify live**: with a counter at 3 on the canvas, "make it count by 10" →
  the model finds the widget from canvas context, recompiles `increment` on
  the running class; the same instance keeps its state and next click reads 13.
- **Text-input widgets**: "type text, press Reverse, see it reversed" →
  built with `ToTextField` straight from the crib. Complex compositions
  (shopping list with checkboxes, count label, progress bar) verified
  interactively.
- **Persist**: save image, quit, reopen — widgets, positions, and state
  intact; behavior still works.
- **Remember** (phase 2): "remember that I live in Porto Alegre" → sticky
  appears; "widget showing the current time in my city" → built with no
  clarifying question; "actually I moved to Madrid" → the same sticky
  updated (no duplicate) *and the model retuned the existing clock widget's
  timezone unprompted*; a name stated in passing was captured implicitly
  and used by the requested widget.

## Operations

| command | what it does |
|---|---|
| `./build.sh` | fresh `pharo/Agent.image` from `src/` (`core` arg skips UI/Bloc/Toplo) |
| `./test.sh` | SUnit suite headless (currently 32 tests) |
| `./run.sh` | open the canvas UI |

Headless acceptance scripts (`pharo ... st scripts/<name>.st`):
`smoke-widget.st` (cold counter generation), `smoke-modify.st` (live
modification with state preservation), `smoke-textfield.st` (text-input
widget), `smoke-facts.st` (remember / use / update / implicit capture).
Each prints the loop transcript for post-mortems.

## Known limitations / accepted risks

- **Rebuild destroys the world**: `build.sh` starts from a pristine image, so
  tooling upgrades currently discard existing widgets. The product thesis
  (image = persistent world) will eventually require migrating tooling into
  a living image instead. Interim: `pharo/backups/` rotation.
- **No capability sandbox**: generated code runs with full image authority.
- **Latency**: a widget takes roughly 15–60s depending on rounds; the status
  line keeps it honest. Crib-sheet prompt caching is the obvious next
  optimization.
- **Log growth**: `logs/gateway.log` includes full payloads (system prompt
  every round); no rotation yet.
- **Reliability is anecdotal**: cold runs have been consistently green, but
  the demo-1 "8 of 10" bar was never formally measured.
- Single user, single space, no multiplayer.
