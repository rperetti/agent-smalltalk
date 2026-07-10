# System Specification (as built)

What the living agentic environment does **today**. The long-term vision lives
in [vision.md](vision.md). This document is kept in sync with the
code; when behavior changes, change this file in the same commit.

*Last updated: 2026-07-09 (Agent Canvas redesign — white cards with colored
category-chip headers across every card type — plus base-prompt guidance for
good-looking generated widgets; 142 clean-image tests).*

## One-paragraph summary

A Pharo 13 image where an LLM (Anthropic `claude-sonnet-5`) writes Smalltalk
that is compiled **live** into the running system. The user summons a floating
prompt bar over a spatial canvas, types a request in English, and a working,
stateful widget appears — built, tested, and repaired by the model through an
agentic tool-use loop. Widgets and their state survive image save/reopen: the
image is the database. The agent can also author visible, pausable routines
whose saved Smalltalk continues to run on a schedule without further model
calls.

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
- System prompt = the base prompt (`prompts/system.md`) + canvas context
  (`## Known facts` and `## Widgets on the canvas`) + the reusable capability
  catalog + a compact `## Scheduled automations` catalog.
- Status callbacks (`statusBlock:`) drive the spotlight's status line:
  `thinking... / evaluating... / working (round N of 30)...`.
- A class-wide mutex makes the gateway the image's **single writer**:
  concurrent asks wait rather than interleaving tool calls and class changes.
- HTTP lives behind `AgentAnthropicTransport`; tests substitute a scripted
  transport and exercise the complete loop without network, credentials,
  latency, or API cost.
- Transcript: every event and the **full HTTP request/response JSON** are
  appended to `logs/gateway.log`; `AgentGateway last log` gives in-image
  access to the most recent run.
- Asynchronous widget failures are posted as keyed system messages and each
  new occurrence is injected into the next tool result. The model therefore
  sees failures that happen after an earlier evaluation returned and must
  repair/re-verify them before finishing.
- Entry points: `AgentGateway ask: 'request'` (headless or programmatic);
  the spotlight uses an instance with a status block.

### AgentSandbox (Core)

Evaluates model-generated code with guardrails:

- Normalizes LF → CR before compiling (JSON delivers LF; Pharo source is CR).
- Catches all errors and answers a report: class, message text, top stack
  frames — plus, for `doesNotUnderstand:`, up to 8 **similar selectors the
  receiver does understand**.
- 10-second evaluation timeout (survives infinite loops); timeout feedback
  explicitly forbids network I/O during widget construction and warns that
  retrying can accumulate partial instances.
- Before each gateway request: copies the image file to `pharo/backups/`
  (rotating, keeps 5) so a corrupted image is recoverable.
- Not sandboxed in the capability sense: the model can touch anything in the
  image. Accepted risk for a single-user prototype.
- `AgentProcessManager` terminates AgentSmalltalk-owned background processes
  (including generated `agent-widget-*` refreshes and
  `agent-automation-*` scheduler/runs) before snapshots and on startup;
  gateway and automation-claim mutex state is reset on startup.
- Save-and-quit detaches persistent canvas content from the native Bloc
  window, preventing a later headless launch from resurrecting AppKit/SDL
  before AgentSmalltalk's startup hooks can run.

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
in state mutators. Widgets subscribe `when:do:for: self` (the base-prompt pattern);
deletion auto-unsubscribes. Verified with generated code: a clock retuned on
a pure fact edit with no request, and a total recomputed purely from a
counter's announcement — no Refresh buttons.

Forked network refreshes apply their result through
`AgentWidget>>runOnUiThreadSafely:`. It catches errors when the queued UI block
actually executes and posts a visible, keyed system message instead of letting
an asynchronous UI exception disappear or crash a worker. The gateway injects
each new async-failure message into the next tool result, forcing the model to
repair and re-verify before it can finish. `setText:on:fontSize:` is the blessed
generated-code path for styled Bloc text, avoiding keyword-precedence mistakes.

### AgentCanvas (UI)

Singleton owning the Bloc space (`AgentCanvas open`, 1280×840, `ToBeeTheme`).

- Widgets live on a content element; `addWidget:` defers to the UI thread via
  `enqueueTask:` when the space is open.
- Additions advance a synchronous monotonic version before that enqueue. The
  gateway observes the version, so its pure-answer heuristic cannot race the
  next Bloc pulse and create a duplicate note.
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

- A white rounded 240×160 card with a soft drop shadow and a hairline border,
  vertical linear layout, 12px padding, draggable (`BlPullHandler`), right-click
  opens a code browser on the generated class ("knowledge = code", made
  visible). Categorised cards (fact/note/system/service/scheduled) add an
  edge-to-edge coloured **chip header** (icon + uppercase category + delete x)
  over a white body; plain generated widgets keep the same shell without a chip.
  The shared chrome lives on `AgentWidget` (`applyCardChrome`,
  `chipHeaderElement`, `chipDeleteButton`, colour hooks) and `AgentSticky`.
- `describe` — one-line self-description including current state; this is how
  the model recognizes existing widgets in later requests.
- Class side: `summonAt: aPoint` (create + place + register) and
  `defineNamed:slots:` — the **blessed class-creation helper** that insulates
  the model from Pharo class-builder API drift. Generated classes go to the
  `AgentSmalltalk-Generated` package.
- `runOnUiThreadSafely:` applies forked results on the live UI thread and
  converts errors into visible system messages; `setText:on:fontSize:` is the
  blessed styled-Bloc-text path, avoiding generated keyword-precedence bugs.
- **Resize grip**: bottom-right corner of every widget (facts and notes
  included), drag-event based, zoom-aware, clamped to 120×80 minimum.
- **Click-to-front**: pressing anywhere on a widget raises it (monotonic
  elevation counter on the canvas), so overlapping cards behave like paper.
- **Delete**: categorised cards carry the delete x in their chip header; plain
  widgets get a floating x (top-right, ignoreByLayout so it never disturbs the
  layout). Delete/Backspace on the canvas removes the current lasso selection.
  Both are undoable (Cmd/Ctrl+Z).
- **Deletion undo**: `removeFromParent` on a canvas widget records it on the
  canvas undo stack (capped at 50, survives image save/reopen); Cmd/Ctrl+Z
  restores the most recent deletion. Unrestorable entries (instances of
  since-removed broken classes) are discarded silently. Widget-internal
  state and moves are not undoable; code changes are Epicea's job.
  `removedFromCanvas` / `restoredToCanvas` lifecycle hooks let behavior-owning
  cards keep durable registration in lockstep with deletion undo.

### AgentTool + AgentToolCard — the agent's own capabilities

The agent builds **reusable tools for itself**, not just widgets for the
user. `AgentTool` (Core) is the base; the agent creates a tool via the
blessed helper `AgentTool defineNamed: #WeatherService purpose: '...'` (a
`slots:purpose:` variant exists for the rare stateful tool), then compiles
**class-side** capability methods (`WeatherService class compile: 'fetchFor:
...'`). Tools land in a live `AgentSmalltalk-Tools` package (not `src/`, so
`update.sh` never wipes them) and persist with the image.

Discovery is the whole game: `AgentTool contextListing` renders a
`## Capabilities you've built` section (each tool's name, purpose, and
class-side selectors) that the gateway appends to every system prompt, so
reuse is automatic — no recurrence-detection. The base prompt teaches the
discipline: consult capabilities, reuse if present, else build a tool, inline
only glue. `AgentTool tools` discovers subclasses directly and returns them
name-sorted; no separate registry can drift from the live classes. Only
selectors defined on each tool's class side are exposed, keeping inherited
framework and private instance methods out of context.

`AgentToolCard` (UI) is the visible face — a white card with a green **SERVICE**
chip, auto-summoned into the **bottom-right toolbox corner** (completing the
geography: facts ↖, notes ↗, system ↙, tools ↘), showing name + purpose,
right-click opening the *tool's*
source to read/tweak. Purpose text wraps and the card grows vertically to fit;
its label follows horizontal resizing rather than staying at a fixed width.
Cards are meta and stay out of the widget context. There is at most one card
per tool. Deleting a card does not delete or hide the capability: the class
continues to persist and appear in the capabilities context.

Verified with generated code and the GUI acceptance pass (2026-07-09):
"weather widget for Tokyo" built one `WeatherService` tool + card + widget;
"compare Tokyo and London" then **reused** `WeatherService fetchFor:` twice
instead of rewriting the fetch; a same-request `#city` fact produced a
fact-backed reactive weather widget; card source browsing, live tool edits,
and save/reopen persistence all worked with no duplicate tool.

### AgentAutomation + AgentSchedule + AgentScheduler (Core)

The agent can author a durable routine as a small `AgentAutomation` subclass
in the live `AgentSmalltalk-Automations` package. Class definition, `run`
compilation, registration, and verification are deliberately separate:

```smalltalk
AgentAutomation
	defineNamed: #MorningWeatherRefresh
	slots: #(target)
	purpose: 'refresh my city weather each morning'.
MorningWeatherRefresh compile: 'run ...'.
MorningWeatherRefresh
	registerOn: (AgentSchedule dailyAtHour: 7 minute: 0)
	dependencies: #(WeatherService).
MorningWeatherRefresh registeredInstance verifyAndEnable
```

Registration creates a visible but paused routine. `verifyAndEnable` starts
one managed background run and enables the schedule only after success.
Normal control is `runNow`, `pause`, `resume`, `schedule:`, and `unregister`.
Each routine owns status, next/last run, last result/error, declared tool
dependencies, and a bounded history of the newest 20 outcomes.
`registeredInstance` retrieves the durable routine across tool calls, and
repeating registration updates it instead of creating a duplicate.
The optional `slots:purpose:` creation form lets a routine retain explicit
live targets such as the widget it refreshes; `requireLiveTarget:` makes a
deleted/off-canvas target fail visibly. Declared dependencies are checked
before every run so a missing tool fails before the generated behavior starts.

Automations are intended to be glue, not duplicate business logic. Widgets
that can be scheduled expose a zero-argument `runAutomatedAction` hook; the
base `AgentWidget` implementation delegates to the common `refresh` method
when one exists, while specialized widgets can override the hook and return an
`AgentAutomationResult`. The preferred routine body for an existing selected
widget is therefore:

```smalltalk
run
	^ (self requireLiveTarget: target) runAutomatedAction
```

If the desired behavior is missing, the agent should add or repair the
widget/service method first and keep the routine tiny. Services (`AgentTool`
subclasses) may opt into the same idea with a class-side
`runAutomatedAction`, but the inherited tool default fails visibly because
most services need arguments from facts or widgets.

`AgentSchedule` intentionally supports only:

- `everyMinutes:` and `everyHours:` intervals;
- `dailyAtHour:minute:` in the machine's local time.

There is no cron syntax, second-level cadence, weekday vocabulary, or
fact-based timezone in v1. `nextAfter:` is deterministic and all scheduler
tests inject `DateAndTime` values rather than sleeping.

`AgentScheduler` owns one supervised `agent-automation-scheduler` ticker.
It atomically claims due work before forking named
`agent-automation-<ClassName>` processes, never overlaps one routine with
itself, contains every error, and continues serving unrelated routines.
`tickAt:` is the synchronous deterministic seam used by headless tests.
Runs time out after 30 seconds.

Scheduled runs execute saved Smalltalk only: **they never call the LLM**.
The accepted v1 path is read-only network access, computation, and image/UI
updates. The prompt explicitly forbids unattended gateway/LLM calls, shell or
file deletion, purchases, public messages, and workflows awaiting input.
This remains a product boundary rather than a security sandbox.

Results are explicit. `AgentAutomationResult unchanged: '...'` records a
quiet success only on the card; `changed: '...'` additionally posts a
coalesced system message. Failures always record history and post a keyed
message. This prevents the scheduler from guessing whether arbitrary values
represent meaningful change.

Image-closed semantics are honest: nothing runs while Pharo is closed. On
reopen, one missed entry is recorded on the card, old occurrences are skipped,
and the next future time is computed—there is no catch-up execution and no
reopen notification spam. Startup is idempotent and snapshot cleanup removes
all scheduler/run processes before the live graph is serialized.

### AgentAutomationCard (UI) — the routines shelf

Each registered automation has one card with a purple **SCHEDULED** chip
(carrying a last-run status badge) in the bottom-center **routines shelf**,
completing the canvas geography without conflating tools (capabilities) with
automations (ongoing commitments). Its body is the routine name, purpose, and a
Schedule / Next run / Last run / Uses key-value table, plus a filled **Run now**
and an outline **Pause/Resume** button; right-click browses the generated
routine class.

Deleting the card immediately unregisters and disables the routine. Normal
canvas undo restores the exact same card, routine, schedule, and history and
re-registers it through the generic widget lifecycle hooks. Generated source
is never deleted implicitly. Automation cards are meta objects and stay out
of ordinary widget context; the gateway instead receives the compact durable
registry listing.

### The sticky family (UI): AgentSticky → AgentFact / AgentNote / AgentSystemMessage

`AgentSticky` (abstract) provides the card: an edge-to-edge coloured chip header
(icon + category + `x`-to-delete) over a white, editable `ToAlbum` body, with an
optional muted meta line (the fact key, the note's question) above the value,
and keyed pile placement. Existing stickies rebuild into the new chrome on
`migrateAfterUpdate` (`repairChrome`, guarded — a failure posts a system message
instead of vanishing). The corners of the canvas carry meaning: **facts pile
top-left, notes top-right, system messages bottom-left, tool cards bottom-right**
(spotlight appears top-center).

#### AgentSystemMessage

The system's own voice — a white card with a gray **SYSTEM** chip, announcing
things the user did NOT initiate. `AgentSystemMessage post: '...' key: #someKey`;
same-key messages **coalesce** (a footer shows the time and `x3`) instead of
stacking.
Deleting is acknowledging. Out of LLM context unless lassoed. Producers
today: `AgentUpdater` (every update announces itself — including headless
updates, whose message waits in the image for the next open), swallowed
note/widget failures, automation failures, and automation-declared meaningful
changes. This is the seed of a future actionable inbox.

### AgentFact (UI)

Sticky-note memory: a white card with an amber **FACT** chip holding one durable
fact — the key shows as a muted meta label over the value in bold. The body is
editable in place (`ToAlbum` — editing the text IS editing the memory); the `x`
button deletes (forgetting
is a physical act). An optional key gives identity: `AgentFact key: #city
body: '...'` creates **or updates** — one sticky per key, ever. New stickies
pile near the top-left. Facts are instances of this hand-written class,
never generated classes. Capture is implicit and loud: the base prompt instructs
the model to save durable facts stated even in passing, and the sticky
visibly appearing on the canvas is the announcement.

### AgentNote (UI)

Answers as paper: a white card with a blue **NOTE** chip holding informational
output — the question as a muted meta line (provenance), the answer as an
editable body, `x`-to-delete. Created two ways: the **gateway heuristic** (a run
that
produced no widget puts its final answer on a note automatically — the text
was the deliverable) or **model-authored** via `AgentNote question:answer:`
(the base prompt steers summaries and lookups here, never into facts). Placement:
next to the selection if one exists, else a pile at the top-right mirroring
the facts pile. Notes are **out of LLM context by default** — conversation
residue, not knowledge — but feed context like any widget when lassoed into
a selection (follow-up questions). A **↩ reply** button under each note is
the one-click form of that: it selects the note (scoping context to its
Q+A) and opens the spotlight, so the follow-up answer lands as a new note
beside it — conversation threads grow *spatially*, not as a chat log.

### AgentSpotlight (UI)

The floating prompt bar: a wrapping multi-line `ToAlbum` editor (cursor,
selection, clipboard; grows vertically with content) plus a `ToLabel` status
line showing loop progress. Enter submits and Esc closes via capture-phase
event filters (they win over the editor). The gateway runs in a forked
process; UI updates are enqueued onto the space pulse. On success the bar
closes itself — answers live on the canvas (widget or note), never in the
bar; on failure it stays open showing the error. While a run is active,
additional submissions are ignored and Esc cancels while leaving the prompt
available to edit and retry.

### The base prompt (`prompts/system.md`)

The system prompt that teaches the model the environment. **Treat it as code**
— it is the highest-leverage artifact in the system. It covers: the tool
protocol and workflow (define class → compile methods → test headless →
`summonAt:`), the AgentWidget contract, the blessed Toplo vocabulary
(`ToLabel`, `ToButton clickAction:`, `ToTextField`, `ToAlbum`, `ToCheckbox
checkAction:`, `ToProgressBar valueInPercentage:`), raw-Bloc recipes for
custom visuals, a *Making widgets look good* design guide (leave the styled
card shell alone and design the interior — type hierarchy, opacity-muted
secondary text, spacing, one accent colour, soft rounded panels — with effort
scaled to the request), live-modification guidance (recompile methods, instances
update instantly), the fact-capture policy (implicit, keyed, update-don't-
duplicate, use silently, never secrets), the network policy (full network
access via `ZnClient` + `STONJSON`; fetch real data when asked, never
present invented data as real, explore APIs frugally), Pharo syntax
pitfalls, when to reach for `search_image` instead of reflection snippets,
and the automation discipline (inspect/modify existing routines, reuse tools,
read live facts, verify before enabling, never call the model in the scheduled
path, and return structured quiet/changed outcomes). Every blessed selector
has been verified against the loaded packages.

## Verified capabilities

- **Generate**: "make me a counter with + and − buttons" → class defined,
  methods compiled, logic tested headless, widget summoned. Includes observed
  self-repair (model added a missing accessor after reading the error).
- **Modify live**: with a counter at 3 on the canvas, "make it count by 10" →
  the model finds the widget from canvas context, recompiles `increment` on
  the running class; the same instance keeps its state and next click reads 13.
- **Text-input widgets**: "type text, press Reverse, see it reversed" →
  built with `ToTextField` straight from the base prompt. Complex compositions
  (shopping list with checkboxes, count label, progress bar) verified
  interactively.
- **Persist**: save image, quit, reopen — widgets, positions, and state
  intact; behavior still works.
- **Remember** (phase 2): "remember that I live in Lisbon" → sticky
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
- **React by hand** (phase 4, verified interactively 2026-07-05): editing a
  `#city` sticky in the GUI retuned a subscribed clock with no request; a
  lassoed sum widget recomputed live as its source counters changed. The
  full canvas — pan, Shift+wheel zoom, lasso across widgets, click-to-front,
  reactive widgets — confirmed working together.
- **Accumulate and reuse tools** (verified headless and interactively
  2026-07-09): a Tokyo weather request created one reusable `WeatherService`
  and visible tool card; a comparison widget reused the same service twice;
  a later same-turn city fact built a nonblocking, reactive weather widget.
  Source edits and image persistence benefited every dependent widget.
- **Keep time without model calls** (verified deterministically 2026-07-09):
  generated a routine class through the blessed API, registered and verified
  it, ran one due occurrence exactly once, emitted only an explicitly changed
  result, skipped a missed occurrence on reopen, and preserved registration
  through card delete/undo. Failure isolation was exercised with two due
  routines: one failed visibly while the other completed.

## Operations

| command | what it does |
|---|---|
| `./build.sh` | FRESH verified image from `src/` (`core` arg skips UI). Builds into a temp image under an isolated `HOME`, runs SUnit by default, then backs up/replaces `pharo/Agent.image` only after success. Supports `--output`, `--no-verify`, `--no-backup`, `PHARO_VM`, and `PHARO_PRISTINE` |
| `./update.sh` | reload tooling from `src/`; widgets/facts survive. Live session → updates in place via `AgentRemote` (localhost:8807 `/update`); else patches the file headless. **Guarded**: both paths require an `UPDATE_OK` token (load raised nothing AND sentinel selectors resolve) or fail loudly leaving the image unchanged — a silent stale-code load once cost a multi-session debugging detour. Diffs via TonelReader + `MCPackageLoader`. Backs up first (keeps 5). Not for Bloc/Toplo — use `build.sh` |
| `./test.sh` | builds a disposable pristine image, loads pinned dependencies, and runs 142 tests; never opens the living image |
| `./run.sh` | open the canvas UI |

Headless acceptance scripts (`pharo ... st scripts/<name>.st`):
`smoke-widget.st` (cold counter generation), `smoke-modify.st` (live
modification with state preservation), `smoke-textfield.st` (text-input
widget), `smoke-facts.st` (remember / use / update / implicit capture),
`smoke-fact-widget.st` (same-request fact resolution into a live widget),
`smoke-tools.st` (build a tool, then reuse it),
`smoke-automations.st` (deterministic scheduler/result/missed/delete-undo
vertical slice; no model call),
`smoke-selection.st` (selection-scoped context + live Selection globals),
`smoke-reactive.st` (reactive clock follows a fact edit; live total follows
counters). Each prints the loop transcript for post-mortems.

## Known limitations / accepted risks

- **`build.sh` replaces the world by design** — but it now does so only after
  a clean temp-image load and verification pass, with an existing image backed
  up first. Routine tooling upgrades should still use `update.sh`, which
  reloads our packages into the living image with widgets and facts intact
  (verified: method added and removed across two updates while the canvas
  survived). Fresh builds remain necessary for dependency (Bloc/Toplo)
  changes or an intentional factory reset.
- **No capability sandbox**: generated code runs with full image authority.
- **Automations are image-resident**: they run only while the image is open,
  skip closed-time occurrences, and never perform unattended LLM inference.
  Running while closed requires an external daemon and is intentionally out
  of scope.
- **Latency**: a widget takes roughly 15–60s depending on rounds; the status
  line keeps it honest. base-prompt caching is the obvious next
  optimization.
- **Log growth**: `logs/gateway.log` includes full payloads (system prompt
  every round); no rotation yet.
- **Memory rides the prompt**: every remembered fact is sent to the
  Anthropic API on every request — inherent to the architecture.
- **One writer at a time, automated**: a running GUI session holds tooling
  in memory; saving it would overwrite a file-level update. `update.sh`
  therefore updates a running session *through* it: `AgentRemote`, a
  localhost-only listener on port 8807 (`GET /ping`, `POST /update`,
  `POST /eval` — operator diagnostics via AgentSandbox, gateway-level trust).
  The listener design is the scar tissue of a multi-session debugging saga;
  the lessons are load-bearing:
  - **`enabled` flag as the only reliable discriminator.** A headless VM
    loading a GUI-saved image inherits every saved flag as stale-true
    (`Smalltalk isHeadless`, `space isOpened`, even `OSWindow allInstances`).
    The one thing that runs fresh each boot is `AgentSandbox class>>startUp:`,
    which resets `enabled := false`; only the GUI `AgentCanvas open` turns it
    on. Headless updates/probes never call open, so they never bind the port.
  - **Forked processes serialize into snapshots and resurrect running OLD
    code**, immune to recompilation — an old-code watchdog spawning rival
    servers was the true engine of the recurring port-bind debuggers. Every
    boot (`disable`) now terminates all agent-remote processes and stray Zn
    listen loops before a fresh listener starts.
  - **`ZnServer start` is async** (binds a beat later); the immediate
    `isRunning` check once orphaned healthy servers, so `ensureRunning` polls
    up to 5s and buries any predecessor first. A watchdog revives it and
    writes `logs/session.status` every 30s.
  `scripts/heal-in-image.st` remains the repair kit for wedged images.
- **Reliability is anecdotal**: cold runs have been consistently green, but
  the demo-1 "8 of 10" bar was never formally measured.
- **Testing is local for now**: `./test.sh` builds a disposable image and is
  run on the user's machine. The mutable `Agent.image` is user data and is
  exercised only by explicit smoke/acceptance runs. Hosted GitHub CI is
  deliberately deferred.
- Single user, single space, no multiplayer.
