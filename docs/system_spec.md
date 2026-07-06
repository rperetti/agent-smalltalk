# System Specification (as built)

What the living agentic environment does **today**. The long-term vision lives
in [vision.md](vision.md). This document is kept in sync with the
code; when behavior changes, change this file in the same commit.

*Last updated: 2026-07-04 (phase 4 built: reactive canvas — AgentKnowledge,
AgentUnknown, canvas announcer; click-to-front; self-healing listener).*

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

- Model `claude-sonnet-5`, max 8192 output tokens, up to **30 tool rounds**
  per request; when ≤3 rounds remain, a note is appended to the tool result
  telling the model to ship instead of polishing. API key from
  `ANTHROPIC_API_KEY` (never logged, never stored).
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
  `thinking... / evaluating... / working (round N of 30)...`.
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

### AgentKnowledge + AgentUnknown (Core) — live values

`AgentKnowledge at: #city` reads the fact sticky's body (the canvas is the
only store); `at:ifAbsent:`, `numberAt:` (first number in the body). Missing
facts answer an **`AgentUnknown`** null-object: carries the missing key,
tests via `isUnknown` (an `Object` extension makes every value answer it),
prints safely (`'unknown (city)'`), and fails loudly beyond that so unknowns
cannot propagate invisibly.

### Reactions (phase 4)

One canvas-wide `announcer`. `AgentFactChanged` fires on agent updates
(`AgentFact key:body:`) and manual sticky edits — announced on focus loss
when Bloc delivers the blur, and guaranteed within ~3s regardless by a
drift sweep (facts remember their last-announced body; a GUI-only watcher
process announces any drift);
`AgentWidgetChanged` fires via the widget convention `self announceChanged`
in state mutators. Widgets subscribe `when:do:for: self` (the crib pattern);
deletion auto-unsubscribes. Verified with generated code: a clock retuned on
a pure fact edit with no request, and a total recomputed purely from a
counter's announcement — no Refresh buttons.

### AgentCanvas (UI)

Singleton owning the Bloc space (`AgentCanvas open`, 1280×840, `ToBeeTheme`).

- Widgets live on a content element; `addWidget:` defers to the UI thread via
  `enqueueTask:` when the space is open.
- **Headless mode**: with no space open, widgets attach to a detached content
  element, so the full generation loop runs (and is tested) without a display.
  In non-interactive sessions `addWidget:` adds directly instead of enqueuing
  (a GUI-saved space never pulses headless, so its task queue never drains).
- **Pan & zoom**: drag on empty background pans; Shift+wheel zooms around
  the cursor (clamped 0.25–3×; the plain wheel stays free for scrolling text
  inside widgets), via a top-left-origin transform on the content element
  (screen = pan + world×zoom). The background color lives on the space root,
  so panning never reveals a void.
- **Lasso selection**: Shift+drag draws a selection rectangle; intersecting
  widgets (facts included) highlight with an accent border. Click on empty
  background clears the selection. Selection state is lazy-initialized —
  singletons in user images are migrated with nil slots, never re-initialized.
- **Selection-scoped context**: with a selection, `contextDescription` lists
  ONLY the selected widgets, in rich form (describe, slots, selectors), and
  binds them to live globals `Selection1..N` and `SelectionAll` so generated
  code operates on the actual objects. Globals persist until the next
  selection (follow-up requests keep working). No selection → full canvas,
  as before.
- Cmd/Ctrl+Enter summons the spotlight.

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
- **Resize grip**: bottom-right corner of every widget (facts and notes
  included), drag-event based, zoom-aware, clamped to 120×80 minimum.
- **Click-to-front**: pressing anywhere on a widget raises it (monotonic
  elevation counter on the canvas), so overlapping cards behave like paper.
- **Deletion undo**: `removeFromParent` on a canvas widget records it on the
  canvas undo stack (capped at 50, survives image save/reopen); Cmd/Ctrl+Z
  restores the most recent deletion. Unrestorable entries (instances of
  since-removed broken classes) are discarded silently. Widget-internal
  state and moves are not undoable; code changes are Epicea's job.

### The sticky family (UI): AgentSticky → AgentFact / AgentNote / AgentSystemMessage

`AgentSticky` (abstract) provides the card: header row (label + `x`-to-delete),
editable `ToAlbum` body, keyed pile placement. The corners of the canvas
carry meaning: **facts pile top-left, notes top-right, system messages
bottom-left** (spotlight appears top-center).

#### AgentSystemMessage

The system's own voice — gray stickies announcing things the user did NOT
initiate. `AgentSystemMessage post: '...' key: #someKey`; same-key messages
**coalesce** (header becomes `system x3 14:32`) instead of stacking.
Deleting is acknowledging. Out of LLM context unless lassoed. Producers
today: `AgentUpdater` (every update announces itself — including headless
updates, whose message waits in the image for the next open) and
swallowed note-creation failures. This is the seed of the future inbox
(see ideas: agent-initiated work).

### AgentFact (UI)

Sticky-note memory: a small pale-yellow
widget holding one durable fact. The body is editable in place (`ToAlbum` —
editing the text IS editing the memory); the `x` button deletes (forgetting
is a physical act). An optional key gives identity: `AgentFact key: #city
body: '...'` creates **or updates** — one sticky per key, ever. New stickies
pile near the top-left. Facts are instances of this hand-written class,
never generated classes. Capture is implicit and loud: the crib instructs
the model to save durable facts stated even in passing, and the sticky
visibly appearing on the canvas is the announcement.

### AgentNote (UI)

Answers as paper: a pale-blue sticky holding informational output — the
question in the header (provenance), the answer as an editable body,
`x`-to-delete. Created two ways: the **gateway heuristic** (a run that
produced no widget puts its final answer on a note automatically — the text
was the deliverable) or **model-authored** via `AgentNote question:answer:`
(the crib steers summaries and lookups here, never into facts). Placement:
next to the selection if one exists, else a pile at the top-right mirroring
the facts pile. Notes are **out of LLM context by default** — conversation
residue, not knowledge — but feed context like any widget when lassoed into
a selection (follow-up questions).

### AgentSpotlight (UI)

The floating prompt bar: a wrapping multi-line `ToAlbum` editor (cursor,
selection, clipboard; grows vertically with content) plus a `ToLabel` status
line showing loop progress. Enter submits and Esc closes via capture-phase
event filters (they win over the editor). The gateway runs in a forked
process; UI updates are enqueued onto the space pulse. On success the bar
closes itself — answers live on the canvas (widget or note), never in the
bar; on failure it stays open showing the error.

### The crib sheet (`prompts/system.md`)

The system prompt that teaches the model the environment. **Treat it as code**
— it is the highest-leverage artifact in the system. It covers: the tool
protocol and workflow (define class → compile methods → test headless →
`summonAt:`), the AgentWidget contract, the blessed Toplo vocabulary
(`ToLabel`, `ToButton clickAction:`, `ToTextField`, `ToAlbum`, `ToCheckbox
checkAction:`, `ToProgressBar valueInPercentage:`), raw-Bloc recipes for
custom visuals, live-modification guidance (recompile methods, instances
update instantly), the fact-capture policy (implicit, keyed, update-don't-
duplicate, use silently, never secrets), the network policy (full network
access via `ZnClient` + `STONJSON`; fetch real data when asked, never
present invented data as real, explore APIs frugally), Pharo syntax
pitfalls, and when to reach for `search_image` instead of reflection
snippets. Every blessed selector has been verified against the loaded
packages.

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
- **Select and operate** (phase 3, verified interactively 2026-07-04): three
  counters (3, 5, 7) selected, "make a widget that shows the sum of these
  selected counters" → SumCounterWidget built against `SelectionAll` holding
  live references; system prompt contained only the selected widgets;
  mutating a counter through `Selection1` and pressing Refresh read 25.
  Pan, Shift+wheel zoom, lasso, and selection-scoped Q&A all confirmed by
  hand on the live canvas.
- **Answer on paper**: pure-text answers (lookups, explanations) land as
  blue notes with question provenance; a scoped Q&A test (facts selected,
  score widget excluded) had the model fetch a sports API on its own and
  answer honestly about unplayed fixtures.
- **Update itself while running**: `./update.sh` against an open session
  delivered code over localhost:8807, migrated on the UI thread, saved, and
  announced itself with a gray system sticky — observed live.

## Operations

| command | what it does |
|---|---|
| `./build.sh` | FRESH `pharo/Agent.image` from `src/` — destroys the world (`core` arg skips UI) |
| `./update.sh` | reload tooling from `src/`; widgets/facts survive. Live session → updates in place via `AgentRemote` (localhost:8807 `/update`); else patches the file headless. **Guarded**: both paths require an `UPDATE_OK` token (load raised nothing AND sentinel selectors resolve) or fail loudly leaving the image unchanged — a silent stale-code load once cost a multi-session debugging detour. Diffs via TonelReader + `MCPackageLoader`. Backs up first (keeps 5). Not for Bloc/Toplo — use `build.sh` |
| `./test.sh` | SUnit suite headless (currently 83 tests) |
| `./run.sh` | open the canvas UI |

Headless acceptance scripts (`pharo ... st scripts/<name>.st`):
`smoke-widget.st` (cold counter generation), `smoke-modify.st` (live
modification with state preservation), `smoke-textfield.st` (text-input
widget), `smoke-facts.st` (remember / use / update / implicit capture),
`smoke-selection.st` (selection-scoped context + live Selection globals).
Each prints the loop transcript for post-mortems.

## Known limitations / accepted risks

- **`build.sh` destroys the world** — but routine tooling upgrades no longer
  need it: `update.sh` reloads our packages into the living image with
  widgets and facts intact (verified: method added and removed across two
  updates while the canvas survived). Fresh builds remain necessary only
  for dependency (Bloc/Toplo) changes.
- **No capability sandbox**: generated code runs with full image authority.
- **Latency**: a widget takes roughly 15–60s depending on rounds; the status
  line keeps it honest. Crib-sheet prompt caching is the obvious next
  optimization.
- **Log growth**: `logs/gateway.log` includes full payloads (system prompt
  every round); no rotation yet.
- **Memory rides the prompt**: every remembered fact is sent to the
  Anthropic API on every request — inherent to the architecture.
- **One writer at a time, automated**: a running GUI session holds tooling
  in memory; saving it would overwrite a file-level update. `update.sh`
  therefore updates a running session *through* it: `AgentRemote`, a
  localhost-only listener on port 8807 (`GET /ping`, `POST /update`, and
  `POST /eval` — operator diagnostics through AgentSandbox; same trust
  level as the gateway, which already executes generated code). Started at
  canvas open and on both sides of every snapshot; never in headless
  sessions. Lifecycle lessons encoded in the hooks: the listener STOPS
  before every save (a snapshotted live socket crashes the next boot) and
  restarts after; snapshots must not run inside Bloc pulse tasks (they die
  silently there) — the updater migrates on the UI thread but always saves
  from the calling thread. `scripts/heal-in-image.st` remains the repair
  kit for wedged images.
- **Reliability is anecdotal**: cold runs have been consistently green, but
  the demo-1 "8 of 10" bar was never formally measured.
- Single user, single space, no multiplayer.
