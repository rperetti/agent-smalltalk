# Phase 5 Specification: The Agent Evolves Its Own Tools

> **Status: DRAFT for discussion.**
>
> (Reuses the phase-5 slot; the wiring draft that briefly held it is
> postponed — see [postponed.md](postponed.md).)

## Goal

So far the agent builds **widgets for the user**. This phase lets it build
**tools for itself** — reusable capability classes it writes once and reuses,
so it stops re-deriving the same API fetch / parse / computation on every
request. The agent stops being purely reactive and starts **accumulating
competence**: a layered, inspectable, tweakable library of its own making.

The substrate makes this nearly free — a tool is just a class that persists
in the image (the image already keeps everything; the agent already compiles
code live). The one hard part, and the focus of this phase, is **discovery**:
the agent reliably knowing what it can already do, so it reuses instead of
rebuilding. This is the same "what goes in the context window" problem already
solved for widgets and facts, applied to the agent's own code.

The money shot: build a weather widget → the agent creates a `WeatherService`
tool and the widget uses it. Later, "compare weather in two cities" → the log
shows the agent **reusing `WeatherService`**, not rewriting the fetch.

## What this phase proves

1. **The agent reuses its own code.** With a capability already built, a new
   request that needs it sends messages to the existing tool instead of
   regenerating the logic — verifiable in the gateway log.
2. **Capabilities are discoverable.** The agent's tools appear in its context
   every request, so reuse is automatic — no recurrence-detection needed.
3. **The toolbox is inspectable and tweakable.** Each tool has a visible card;
   right-click opens its source; a human fix sticks and benefits every reuse.

## Design

### AgentTool — the thin base (Core)

- `AgentTool` (in `AgentSmalltalk-Core`) is the base every agent-built tool
  subclasses. Subclassing is what makes a class *discoverable as a tool*
  (`AgentTool allSubclasses`), so registration is free.
- Contract, deliberately minimal:
  - class-side **`purpose`** → a one-line description ("fetch current weather
    for a city").
  - the capability is the tool's **methods** — blessed default form is
    stateless **class-side** methods (`WeatherService fetchFor: 'Tokyo'`),
    since most tools are services; instance state allowed when needed.
- Generated tool classes live in a `AgentSmalltalk-Tools` package created
  **live** (like `AgentSmalltalk-Generated` widgets) — NOT a `src/` package,
  so `update.sh` never wipes them. They persist with the image.

### Discovery — the whole game (context section)

- The gateway's system prompt gains a **`## Capabilities you've built`**
  section, always present, listing every `AgentTool` subclass: name,
  `purpose`, and its capability selectors (reusing `AgentImageSearch`-style
  listing). Empty state: "(none yet — build tools for reusable capabilities)."
- This is the mechanism that makes reuse automatic. If a tool is in context,
  the agent uses it; the design effort goes here.

### Crib discipline — consult, build, reuse

New crib section teaching the loop:

- **Before** writing code that fetches, calls an API, parses a format,
  geocodes, or performs any reusable capability: check
  `## Capabilities you've built`.
- **If a tool covers it**, use it (send its methods). Do not rewrite it.
- **If not, and it's reusable**, build it: `AgentTool subclass:` (via the same
  blessed helper pattern as widgets), add class-side `purpose`, implement and
  **test** the capability method(s), then use it from the widget.
- **Inline only trivial glue.** Always-build for real capabilities; no
  recurrence-detection — reuse emerges from the toolbox being in context.

### AgentToolCard — the visible/tweakable face (UI)

- When the agent builds a tool, a small card is summoned into a **toolbox
  pile at the bottom-right corner** — completing the canvas geography (facts
  ↖, notes ↗, system ↙, **tools ↘**).
- The card shows the tool's name + `purpose`; **right-click opens the tool
  class's source** (reusing `AgentWidget>>browseSource`, pointed at the tool
  class), so the user can read and tweak — a fix sticks for every future reuse.
- Cards are lightweight references to their tool class, deletable (deleting a
  card does not delete the tool; a separate "forget this tool" is out of scope
  for v1). Tools remain discoverable via context regardless of cards.

## Acceptance script

1. **"Make me a weather widget for Tokyo."** → the agent builds a
   `WeatherService` tool (`AgentTool` subclass, `purpose`, `fetchFor:`) *and*
   a widget that calls it; a tool card appears bottom-right. Weather shows.
2. **"Make a widget comparing the weather in Tokyo and London."** → the
   gateway log shows the agent seeing `WeatherService` in
   `## Capabilities you've built` and **reusing** it (two `fetchFor:` calls),
   not rewriting the API code. *(Money shot — reuse, verifiable headless.)*
3. Right-click the `WeatherService` card → its source opens; edit a method
   (e.g. add wind speed); both weather widgets pick up the change.
4. Save, quit, reopen → the tool, its card, and the widgets that use it are
   all intact and still work (tools persist with the image).

Steps 1–2 are headless-verifiable (`scripts/smoke-tools.st`); 3–4 need the
GUI pass.

## Non-goals (parked, see [ideas.md](ideas.md))

- **Toolbox curation** (pruning redundant/overlapping tools, "forget this
  tool") — real once a toolbox accumulates, not v1.
- **Tools composing tools** is *allowed* (a tool may call another) but not
  specially scaffolded; emergent for now.
- **Agent adds gateway-level tools** to its own tool-use schema — rejected for
  this phase; tools are library classes it calls via `evaluate_smalltalk`.
- **Tools subsuming the crib sheet** — the long game, parked in ideas.
- Auto-generated tests for tools; tool versioning.

## Open questions (to settle before building)

1. **Card per tool, or on demand?** Auto-summon a card for every tool
   (discoverable/tweakable but can clutter bottom-right) vs. only when the
   user asks "show your tools." Recommendation: auto-summon, since the whole
   value of the card is passive inspectability, and tools are far fewer than
   widgets — revisit if it clutters.
2. **How does the agent create a tool class** — a blessed helper like
   `AgentTool defineNamed:purpose:` (insulates from class-builder drift, the
   `defineNamed:slots:` lesson) or plain subclassing? Recommendation: a
   blessed helper, same reasoning as widgets.
3. **Selectors in context: all, or a capped/curated set?** A tool with many
   private helpers would bloat the listing. Recommendation: list only class-
   side (capability) selectors, or a tool-declared `apiSelectors`, to keep the
   context tight. Lean toward class-side-only by default.
