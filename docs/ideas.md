# Ideas parking lot

Things we've deliberately deferred, so they don't evaporate. Each entry says
where it came from and why it's parked. This file and the other files under
`docs/` are the project's planning and issue tracker; GitHub Issues are not
used.

## Undo should re-establish a reactive widget's subscriptions

*From a delete+undo crash on a reactive widget (2026-07-06).*

`removeFromParent` unsubscribes a widget from the canvas announcer (so deleted
widgets don't react); `undoDeletion` re-adds the instance but does **not**
re-run its subscription setup (which lives inline in the generated
`initialize`). So undoing a *reactive* widget restores its presence but not its
live wiring — a restored total/chart sits inert until rebuilt. (The dangerous
half — a stale off-canvas subscriber crashing the UI — is already prevented by
`pruneStaleSubscriptions`; this entry is only about restoring liveness.)

Approaches when picked up:
- **Reaction-setup hook**: crib teaches reactive widgets to put subscriptions
  in a `subscribeReactions` method called from `initialize`; `undoDeletion`
  re-invokes it on restore. Clean, but only helps widgets built after the
  convention exists.
- **Canvas-mediated dispatch**: widgets declare interest declaratively and the
  canvas delivers only to on-canvas widgets, so subscription lifecycle follows
  canvas membership automatically. The correct architecture, but a real
  refactor that changes how all generated reactions are written.

Parked because: it's an edge case (delete *then* undo a *reactive* widget),
the crash risk is already structurally handled, and the proper fix
(canvas-mediated dispatch) deserves its own pass. Workaround: rebuild the
widget, or ask the agent to re-wire it.

## Hosted GitHub CI

*From the first GitHub Actions experiment (2026-07-08).*

Testing currently runs only on the user's machine through `./test.sh`, which
builds a disposable pristine image and leaves the living `Agent.image`
untouched. The first hosted Linux workflow crashed inside the official Pharo
VM's bundled `libgit2` during Iceberg dependency fetching, before any project
test ran.

Parked because: local clean-image testing is reliable and sufficient for the
current single-user prototype. Revisit hosted GitHub CI when broader
collaboration makes it valuable, ideally with an upstream Pharo/Linux Git fix
or a deliberately prebuilt dependency image.

## Open-source readiness pass

*From the base-prompt rename discussion (2026-07-06), with an OSS release in mind.*

Before (or as part of) making the repo public, a dedicated polish pass:
- **LICENSE** — none yet; pick one (MIT is the usual default for a prototype).
- **README for newcomers** — currently assumes Pharo familiarity; add a
  "what is this / why Pharo / how the pieces fit" intro and a screenshot/gif
  of the canvas in action.
- **Explain the load-bearing oddities** — `scripts/heal-in-image.st`, the
  `logs/` breadcrumbs (`startup.log`, `remote.log`, `session.status`), and the
  `update.sh` vs `build.sh` distinction each deserve a sentence on *why* they
  exist, so a contributor doesn't mistake them for cruft.
- **Naming sweep** — one more read for anything else that reads as
  internal-jargon rather than industry-standard (the base-prompt rename was
  the first of these).
- **Contributing notes** — how to run tests, the src/-is-truth vs image-is-
  world model, the "update.sh not build.sh" habit.

Parked because: the code should settle a bit more first; do this pass when a
release actually feels near.

## Agent-written tools may subsume parts of the base prompt

*From the self-evolving-tools brainstorm (2026-07-06).*

The base prompt (`prompts/system.md`) is **hand-written** capability knowledge —
blessed APIs, recipes, examples we maintain by hand. Once the agent builds its
own reusable **tools** (see the tools feature: library classes it writes and
reuses), those are **agent-written** capability knowledge that lives in the
image and is already listed in context. Over time the two converge: a mature
toolbox could replace whole sections of the base prompt (why teach the Bloc-button
recipe by hand if the agent has a tested `LabeledButton` tool it reuses?).

The long game: the base prompt shrinks toward *bootstrapping* knowledge (how to write
Pharo, the AgentWidget contract, how to build a tool) and the agent's own
toolbox carries the *accumulated* knowledge. The system teaches itself.

Parked because: only meaningful once the tools feature exists and a real
toolbox has accumulated. Revisit then — and watch whether base-prompt sections start
feeling redundant with tools the agent already has.

## Thread-aware reply (full conversation context)

*From using the reply button (2026-07-06).*

The ↩ reply on a note scopes context to **that one note** (its Q+A). In a
multi-turn thread this means a follow-up only sees the immediately previous
answer, not the whole conversation — for full history the user must lasso all
the notes in the thread. Fine for now, but worth handling: replies could
automatically include the **whole thread** a note belongs to.

Approaches to explore when it matters:
- **Provenance chain**: each follow-up note remembers its parent note; reply
  walks the chain and selects/serializes the lineage (root → this note).
- **Thread id**: notes born from a reply share a thread tag; reply scopes to
  all notes with that tag.
- **Spatial**: since threads already grow rightward from their parent, group
  by proximity/row — but that's brittle once the user rearranges.

Recommendation when picked up: the provenance chain — it's explicit, survives
rearrangement, and the note already carries a `question`; adding a `parent`
reference is small. Current workaround (lasso the whole thread) stays as the
manual escape hatch.

## Variables on the canvas

*From the phase 2 brainstorm (2026-07-03), sparked by fact keys like `#city`.*

A fact key is secretly a **global variable**: set it once, use it as input
anywhere on the canvas (`AgentKnowledge at: #city` — the lookup queries the
sticky widgets, so the canvas remains the single store). Widgets could bind
to variables at build time or hold live references so editing the sticky
re-parameterizes every widget wired to it.

The rabbit hole underneath (later / maybe never): local/temporary variables;
visually **wiring** a variable to a widget; scoping rules where a local
overrides a global for one widget or one region of canvas. This starts to be
a visual programming language — which is also where the original spec's
"draw a line from Email to To-Do" use case lives.

Parked because: phase 2 only needs keys as identity-for-updates. The variable
semantics deserve their own phase with the wiring UX thought through.

## Preferences and settings as scoped knowledge

*From the phase 2 brainstorm.*

"I like dark widgets" is knowledge *about how to build*, not about the world
— a preference. Preferences feel like **scoped variables**: scoped to a
widget class, to a region, or to the whole canvas. The deep end: the agent's
own instructions (base prompt fragments) becoming visible, editable objects on
the canvas — the system's behavior becomes direct-manipulable.

Parked because: needs the variables story first, and it changes how the base prompt is
assembled per request.

## Promote a note to a fact

*From the answer-notes brainstorm (2026-07-03).*

A note sometimes turns out to contain something durable ("actually, keep
this"). Today the path is asking the agent to copy it into a fact; a direct
gesture (drag note onto the facts pile? a button?) would make the
ephemeral→durable transition a physical act, like deletion already is.
Parked because: needs so little that it can ride along whenever sticky
interactions next get touched.

## Agent-initiated work: scheduled automations and the inbox

*From the system-message brainstorm (2026-07-04).*

Today every agent action is a response to a spotlight request. The next
category: the agent acting on its own schedule — cron-like automations
("refresh the scores widget every morning", "watch this API"), long-running
background tasks, and follow-ups. That requires a channel where the agent
can report without being asked and **request user input** (approve/deny,
answer a question) — an inbox with actionable messages, not just
notifications. The system-message widget is deliberately the seed of this:
same objects, later docked into a tray with buttons.

Parked because: scheduling needs its own design pass (what triggers runs,
what budget, how to stop a runaway automation) and deserves the phase
spotlight when it comes.

## Apps on the canvas (beyond widgets)

*From the apps brainstorm (2026-07-04).*

When a request outgrows a card ("build me an expense tracker with views and
forms"), the agent needs an app-grade container. Candidate paths:

- **Toplo inner windows** (`ToInnerWindow`): window elements INSIDE the Bloc
  space -- richest container available today, everything already built
  (drag, lasso, context, persistence, live modification) keeps working.
  Nearest-term path.
- **Spec2 on the Toplo/Bloc backend** (in development upstream): real app
  framework rendering onto the canvas. Two under-appreciated advantages:
  Spec2 is deeply present in LLM training data (books, MOOC) so generation
  reliability may be HIGHER than raw Bloc; and presenters are headless-
  testable, letting the agent click its own app's buttons during the build
  loop. Watch upstream maturity.
- **Spec2 satellite windows + proxy card on canvas**: works today, no
  bridging; the canvas holds a describable handle, the app lives in its own
  window.

The toolkit-agnostic core to design first: the **AgentApp contract** -- an
app is a canvas citizen (describe, browsable source, selection, image
persistence) with a model object separate from its views so features can be
iterated against the model and views regenerated cheaply.

Parked because: no user request has outgrown a card yet; revisit at the
first real "build me an app" moment, and check Spec2-on-Toplo maturity then.

## Theming the canvas and widgets

*From the phase 2 brainstorm.*

User-controlled look of the whole environment: canvas colors, widget default
style, dark mode. Toplo ships a theme system (`ToBeeTheme`, `ToBeeDarkTheme`,
style sheets) we already install — theming could start as "expose theme
choice" and grow into "the agent restyles widgets on request", which
connects back to preferences-as-knowledge.

Parked because: cosmetic until knowledge + variables give it something to
hang on (a `#theme` fact scoped to the canvas is the natural shape).
