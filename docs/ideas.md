# Ideas incubator

Product opportunities and feature possibilities that should not evaporate, but
are not yet understood or validated well enough to order in the
[backlog](backlog.md). An idea becomes backlog work when there is enough
evidence to state a proposed outcome and observable acceptance criteria.

This file is intentionally not a bug list, security register, or operations
queue. Known defects and actionable maintenance belong in `backlog.md`. Ideas
that were seriously evaluated and consciously deferred belong in
[postponed.md](postponed.md).

## Agent-written tools may subsume parts of the base prompt

*From the self-evolving-tools brainstorm (2026-07-06).*

The base prompt (`prompts/system.md`) is hand-written capability knowledge:
blessed APIs, recipes, and examples maintained by the platform. Agent-written
tools are executable capability knowledge that already lives in the image and
is listed in context. Over time the two may converge: a mature, tested toolbox
could replace prompt recipes that teach the same capability by hand.

The long game is a base prompt focused on bootstrapping—Pharo syntax, the
`AgentWidget` contract, tool creation, and safety disciplines—while the agent's
own healthy toolbox carries accumulated domain knowledge. The system teaches
itself without making the bootstrap prompt grow forever.

Open questions:

- What evidence proves a tool is reliable enough to replace a prompt recipe?
- How are examples, tests, versions, and dependent widgets attached to a tool?
- How does the agent recover when a previously healthy external API drifts?
- What is the minimum bootstrap vocabulary that must always remain available?

Promotion trigger: several tested tools make specific prompt recipes
demonstrably redundant. The actionable toolbox lifecycle foundation is tracked
as [AS-15](backlog.md#as-15--add-provenance-health-and-rollback-for-generated-artifacts)
and [AS-16](backlog.md#as-16--make-tool-card-removal-match-its-visible-meaning).
The implemented [base-prompt contract](system_spec.md) sets the evidence
threshold for replacing a recipe.

## Thread-aware reply

*From using the reply button (2026-07-06).*

The reply action on a note scopes context to that one note's question and
answer. In a multi-turn thread, a follow-up therefore sees only the immediately
previous answer unless the user lassos the whole thread.

Approaches worth exploring:

- **Provenance chain:** each follow-up note remembers its parent; reply walks
  the lineage from root to the selected note.
- **Thread ID:** notes born from a reply share a thread identity.
- **Spatial inference:** notes in one row/proximity are treated as a thread,
  though this becomes brittle after rearrangement.

Current preference: provenance chain. It is explicit, survives rearrangement,
and builds naturally on the note's existing question provenance. The current
manual workaround is to lasso every note that should participate.

Promotion trigger: real multi-turn note use makes repeatedly selecting the
whole thread a noticeable burden.

## Variables on the canvas

*From an early brainstorm (2026-07-03), sparked by fact keys such as
`#city`.*

A keyed fact already behaves like a visible global variable:
`AgentKnowledge at: #city` queries the fact object on the canvas, keeping the
canvas as the store. Widgets can bind to that value and react when the fact is
edited.

Possible extensions:

- temporary or local variables;
- visible binding of a variable to a widget;
- regional scope where a local value overrides a canvas-wide value;
- transforms between a value and one consumer;
- a direct-manipulation vocabulary for inspecting which objects depend on a
  variable.

This begins to form a visual programming language and connects to the original
"draw a line from Email to To-Do" use case.

Promotion trigger: global keyed facts become insufficient or users cannot
understand which widgets depend on which values. Visible wiring itself remains
consciously deferred in [postponed.md](postponed.md).

## Preferences and settings as scoped knowledge

*From an early brainstorm.*

"I like dark widgets" is knowledge about how the environment should behave,
not a fact about the external world. Preferences may be scoped to the whole
canvas, one region, one class, or one request. At the deep end, prompt fragments
and system behavior could become visible, editable objects on the canvas.

Open questions:

- How is a preference distinguished from an ordinary fact?
- Which scope wins when preferences conflict?
- Which preferences may influence generated code versus only appearance?
- How does the user see why a preference was applied?

Promotion trigger: the variable/scope model is concrete enough to state
resolution rules and a user interaction.

## The system prompt as a canvas citizen

*From a brainstorm (2026-07-14).*

The base prompt (`prompts/system.md`) already governs everything the agent
does, but it lives off-canvas: invisible, and out of reach for an agent asked
to act on "everything" it has access to. Putting it (or scoped fragments of
it) on the canvas would let an agent inspect and, potentially, edit its own
operating instructions the same way it inspects facts and widgets today.

This is the sharpest-edged member of the
[preferences-as-scoped-knowledge](#preferences-and-settings-as-scoped-knowledge)
family: that idea already floats "prompt fragments and system behavior could
become visible, editable objects on the canvas," and this is that idea taken
to its most literal, highest-stakes conclusion—the root prompt itself, not
just a preference layered on top of it.

Open questions:

- Read-only visibility versus editability: does exposing the prompt mean the
  agent can see it, or that it can change it?
- If editable, what stops a run from degrading or disabling its own safety
  disciplines, and who/what reviews a self-authored prompt edit?
- Is the whole prompt one object, or does it decompose into scoped
  fragments (bootstrap vocabulary vs. accumulated recipes), echoing the
  [agent-written-tools-may-subsume-the-base-prompt](#agent-written-tools-may-subsume-parts-of-the-base-prompt)
  split?
- Does this need its own provenance/versioning/rollback story before it can be
  touched safely, or does it ride on the same foundation as generated
  artifacts ([AS-15](backlog.md#as-15--add-provenance-health-and-rollback-for-generated-artifacts))?
- Should this start read-only (observability only) with editability
  deliberately deferred?

Promotion trigger: needs more brainstorming before this is concrete enough to
promote—in particular, a stance on read-only vs. editable, and how self-edits
would be reviewed.

## Promote a note to a fact

*From the answer-notes brainstorm (2026-07-03).*

A note sometimes becomes durable knowledge: "actually, keep this." Today the
user asks the agent to copy it into a fact. A direct gesture—perhaps a menu
action or dragging the note to the facts area—could make the transition from
ephemeral answer to durable memory a visible physical act.

Open questions:

- Does promotion preserve the original note as provenance?
- How is a fact key selected or suggested?
- What happens when the proposed key already exists?
- Should edited or externally fetched notes require confirmation before they
  become always-sent facts?

Promotion trigger: note/fact interactions are next being changed, or users
repeatedly ask the agent to remember existing notes.

## Automation follow-ups: event triggers and an actionable inbox

*From the system-message brainstorm (2026-07-04).*

Visible interval/daily automations now execute saved Smalltalk without
unattended model calls. A broader category remains:

- event triggers such as an incoming email;
- long-running follow-ups;
- work that must ask the user for input;
- approve/deny decisions;
- actions with externally visible or irreversible effects.

This requires an actionable inbox, explicit approval states, idempotency, and a
clear capability model rather than today's notification-only system messages.

Promotion trigger: the current read-only scheduled slice accumulates real use,
and the automation authority decision in
[AS-06](backlog.md#as-06--decide-whether-automation-restrictions-are-policy-or-enforcement)
has been made.

## Apps on the canvas

*From the apps brainstorm (2026-07-04).*

Some requests will outgrow a 240x160 card: an expense tracker with forms,
multiple views, or substantial navigation needs an app-grade container.

Candidate paths:

- **Toplo inner windows (`ToInnerWindow`):** app windows inside the existing
  Bloc space, preserving drag, selection, context, persistence, and live
  modification.
- **Spec2 on the Toplo/Bloc backend:** an app framework with stronger model/view
  separation and potentially more reliable generation from existing training
  material; maturity must be checked when the need is real.
- **Spec2 satellite windows with canvas proxies:** a describable handle remains
  on the canvas while a separate native window hosts the app.

The toolkit-independent concept to design first is an `AgentApp` contract: a
canvas citizen with a model separate from its views, browsable source,
description, selection semantics, image persistence, and testable behavior.

Promotion trigger: a concrete request cannot be served comfortably or legibly
inside a card.

## Theming the canvas and widgets

*From an early brainstorm.*

Possible scope ranges from exposing `ToBeeTheme`/`ToBeeDarkTheme` selection to
letting the agent restyle generated widgets in response to a scoped preference.

The useful version is likely connected to preferences-as-knowledge rather than
being a standalone color toggle: a visible `#theme` or design preference should
have clear scope, precedence, and an explanation of what it changes.

Promotion trigger: preferences/scoping provide a product model for theme state,
or visual inconsistency becomes a concrete usability problem.

## A model router for choosing the model per request

*From the open-source-readiness discussion (2026-07-13).*

Every request currently goes to one configured model. Requests differ in need: a
quick fact edit or a routine restyle does not require the most capable (and most
expensive) model, while novel widget generation or hard debugging does. A router
could pick the model per request — by task type, estimated difficulty,
cost/latency budget, or explicit user preference — so the system spends
capability where it matters.

This sits on top of a provider-neutral inference boundary: once the gateway can
reach more than one backend
([AS-14](backlog.md#as-14--introduce-a-provider-neutral-inference-boundary),
building on the external-inference decision in
[ADR-0001](adr/0001-external-inference-boundary.md)), the router decides which
one a given request uses.

Open questions:

- What signal decides the model — task type, a difficulty estimate, a
  cost/latency budget, prior failures, or a visible user setting?
- Does the router classify then route, or start cheap and escalate on
  failure/repair?
- Is the choice visible and overridable on the canvas, and recorded in a run's
  provenance and diagnostics?
- How does routing interact with the tool-use loop — can the model change
  mid-run?

Promotion trigger: more than one backend is actually available (AS-14 lands) and
real usage shows a cost or capability mismatch from routing everything to one
model.

## Promote living-world code from the image to the platform source

*From the documentation review (2026-07-13).*

Code flows one way today: the platform source (`src/`) is built, tested, and
committed, then loaded into a living world through an update. Nothing flows
back. But the living world is exactly where the agent builds—classes, tools,
and widgets accumulate in the running image. When a functionality built from
inside one world proves useful enough and generic enough to belong to every
world, there is no path to lift it out of that image and into the shared,
versioned foundation. It stays trapped in one person's `.image`, invisible to
the repository and to every other world.

Promotion would turn image-resident code into committed Tonel source: extracted,
generalized past the one canvas it grew up in, tested to the standard platform
code is held to, and reconciled with the world it came from so the local copy is
superseded rather than left to drift.

Open questions:

- What proves a piece is generic enough—that it does not secretly depend on one
  canvas's facts, instances, or positions?
- How is it extracted from the live image into versioned Tonel source with
  tests, and who authors the tests and review that platform code demands?
- Does promotion lift the source verbatim, or generalize and rename it on the
  way out?
- After promotion, how does the originating world reconcile its now-redundant
  local copy on the next update?
- What provenance records that a platform capability originated in a living
  world, and by which agent run?

This is the code counterpart to
[agent-written tools subsuming the base prompt](#agent-written-tools-may-subsume-parts-of-the-base-prompt):
that idea moves accumulated *knowledge* from the world back toward the platform
prompt; this one moves accumulated *code* from the world back into the platform
source. Both depend on the artifact provenance, health, and export foundations
in [AS-15](backlog.md#as-15--add-provenance-health-and-rollback-for-generated-artifacts)
and the export/import path in
[AS-03](backlog.md#as-03--define-persistence-and-recovery-semantics).

Promotion trigger: a capability built inside a world is repeatedly re-created or
hand-copied into `src/` by a human, or AS-15/AS-03 make image-to-source
extraction concrete enough to design the gesture.

## A browser demo image, playable from GitHub

*From wanting the project to be tried, not just read (2026-07-16).*

Trying this today costs a clone, a Pharo 13 image and VM downloaded by hand
from files.pharo.org, an Anthropic key with credits, and a ~1.5 minute build —
before anyone sees a single widget appear. The README's screenshot carries the
whole first impression. A demo image running in the browser, linked from the
README, would let someone form a real opinion in a minute: press
Cmd/Ctrl+Enter, ask for a counter widget, watch it get compiled and placed.
The goal is enticement, not production quality. If it convinces people to clone
and set up properly, it has done its job; a demo that is slow, feature-clipped,
or occasionally broken still beats a static PNG.

Two hard parts, roughly independent:

- **Getting the image into a browser.** Pharo images can run in JavaScript
  hosts (SqueakJS-style interpreters, and the ongoing WASM VM work), but the
  canvas is Bloc/Alexandrie, which leans on native rendering. Whether the real
  canvas renders acceptably in a browser VM — or whether a demo needs a
  different, thinner front end for the same living image — is unknown and worth
  a spike before anything else. A ~95 MiB image plus `.changes` is also a rude
  first download; what a trimmed demo image contains is part of the question.
- **Inference without handing out a key.** Every interesting interaction is a
  paid model call. Options: a hosted proxy with rate limits and a spend cap
  (real money, real abuse surface), bring-your-own-key pasted into the page (a
  key in a browser page we host — see [security.md](security.md)), or no live
  inference at all, replaying canned responses for a few scripted prompts. The
  canned path is cheapest and safest and still shows compile-and-place; it just
  can't show the agent handling *your* question, which is the part that
  convinces.

Open questions:

- Does the spike show Bloc/Alexandrie rendering usefully in a browser VM, and
  at what load time?
- Scripted replay or live inference? If live, who pays, and what stops the demo
  from becoming a free API proxy?
- Sandbox blast radius: the demo agent compiles arbitrary generated Smalltalk
  in a world strangers share or reset. What is the reset story, and does one
  visitor's session leak into the next?
- Where does it live — GitHub Pages off this repo, or a separate host — and who
  keeps it from rotting behind `src/` once it exists?
- Does the demo image build from `src/` in CI, or is it a hand-made artifact
  that drifts?

Promotion trigger: a spike proves an image renders and responds in a browser at
a tolerable size and load time, and the inference stance is settled. Absent
that, a cheaper answer to the same problem — a recorded screencast in the
README — may be the honest substitute.

## Adding an idea

New entries should answer, briefly:

- What user opportunity or product hypothesis is this exploring?
- What evidence or observation prompted it?
- What important questions are still unresolved?
- What concrete event would justify promoting it to the backlog?

Avoid adding implementation checklists here. Once the outcome and acceptance
criteria are clear enough for a checklist, create a backlog item instead.
