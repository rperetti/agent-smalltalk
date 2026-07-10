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
as [AS-15](backlog.md#as-15--add-provenance-health-and-rollback-for-generated-artifacts),
[AS-16](backlog.md#as-16--make-tool-card-removal-match-its-visible-meaning),
and [AS-19](backlog.md#as-19--make-the-base-prompt-a-tested-consistent-contract).

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

*From the phase-2 brainstorm (2026-07-03), sparked by fact keys such as
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

*From the phase-2 brainstorm.*

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

*From the phase-2 brainstorm.*

Possible scope ranges from exposing `ToBeeTheme`/`ToBeeDarkTheme` selection to
letting the agent restyle generated widgets in response to a scoped preference.

The useful version is likely connected to preferences-as-knowledge rather than
being a standalone color toggle: a visible `#theme` or design preference should
have clear scope, precedence, and an explanation of what it changes.

Promotion trigger: preferences/scoping provide a product model for theme state,
or visual inconsistency becomes a concrete usability problem.

## Adding an idea

New entries should answer, briefly:

- What user opportunity or product hypothesis is this exploring?
- What evidence or observation prompted it?
- What important questions are still unresolved?
- What concrete event would justify promoting it to the backlog?

Avoid adding implementation checklists here. Once the outcome and acceptance
criteria are clear enough for a checklist, create a backlog item instead.
