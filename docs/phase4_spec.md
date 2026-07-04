# Phase 4 Specification: The Canvas Becomes Reactive

> **Status: agreed scope (2026-07-04).** All open questions resolved:
> Album change events with focus-loss fallback for manual edits; one
> canvas-wide announcer with typed events; AgentKnowledge + AgentUnknown
> in Core.

## Goal

Facts stop being mere prompt text and become **live named values** that
widgets read and react to. Edit the `#city` sticky — by hand, mid-thought —
and the clock built "for my city" retunes itself without a single request.
This is the "variables" idea from [ideas.md](ideas.md) promoted to a phase,
and the vision's "Data that Works" use case taking root: data on the canvas
behaves like an application.

Why this over the other parked candidates: variables are the **foundation
the rest stand on**. Preferences are scoped variables; theming hangs off a
`#theme` value; apps need models their views react to; even automations
want values to watch. Scheduled automations + the inbox stay parked — they
need their own trust/interaction design pass.

## What phase 4 proves

1. **The canvas is the store**: `AgentKnowledge at: #city` answers the live
   value by querying the sticky — no second database, no sync problem.
2. **Change propagates**: editing a fact (by hand in the sticky, or by the
   agent) announces, and subscribed widgets update themselves.
3. **Widgets can be reactive too**: the phase 3 sum widget loses its Refresh
   button — counters announce, the total recomputes.

## Workstreams

### 1. AgentKnowledge — the lookup facade (Core package)

- `AgentKnowledge at: #city` reads the fact sticky's body (the canvas
  remains the single source of truth). Keys are Symbols (`#city`):
  interned names compared by identity, the Smalltalk idiom for
  identifiers as opposed to content strings.
- Missing fact → an **`AgentUnknown`** (null-object, also Core), never a
  magic string: it carries the missing `key`, answers `isUnknown` (true —
  with `Object>>isUnknown` answering false, so ANY value can be tested),
  and renders safely (`asString` → `'unknown (city)'`). Deliberately
  minimal protocol: anything beyond testing/printing fails loudly, so
  unknowns cannot propagate invisibly through computations.
- Convenience: `numberAt:` for numeric bodies.
- Crib: blessed as THE way generated code reads user facts; widgets check
  `isUnknown` before computing and render `asString` when unknown.

### 2. Fact change announcements

- The canvas gets an announcer. `AgentFact >> body:` (agent updates) and the
  body editor's text-change hook (manual edits — the risk point; probe
  Album's change events at build time) announce a `FactChanged` carrying the
  key and fact.
- Crib pattern for dependent widgets: subscribe in `initialize`, store the
  subscription, unsubscribe on `removeFromParent` (or use weak
  subscriptions) so deleted widgets don't leak handlers.

### 3. Widget change announcements (closing phase 3's deferral)

- Convention: state-mutating widget methods call `self announceChanged`.
  `AgentWidget` provides it (announces `WidgetChanged` on the canvas
  announcer); the crib teaches it as part of the skeleton (call it from
  `refresh`).
- Derived widgets (totals, charts) subscribe to their sources — the
  `SelectionAll` live references from phase 3 become *subscriptions*, not
  just reads.

### 4. Graceful degradation

- A widget whose fact is deleted receives an `AgentUnknown` and shows its
  `asString` rather than erroring; asking about it prompts the agent to
  request the missing fact (the unknown's key tells it exactly what to
  ask for).

## Acceptance script

1. With `fact[city]` on the canvas: **"make a clock for my city that stays
   correct if my city changes"** → widget built, subscribed.
2. **Edit the sticky by hand** to another city. The clock retunes with no
   request. *(The money shot of this phase.)*
3. "I moved to Tokyo" → agent updates the fact → clock follows.
4. Lasso three counters: **"make a live total of these"** → no Refresh
   button; clicking a counter updates the total instantly.
5. Delete the `#city` sticky → clock shows its unknown state, no error;
   asking "what time is it at home?" makes the agent ask for the city.
6. Save, quit, reopen → subscriptions still work (announcer and
   subscriptions live in the image).

## Non-goals (still parked, see [ideas.md](ideas.md))

- Local/temporary variables, visual wiring, scope overrides.
- Preferences and theming (they build ON this phase's mechanism).
- Spreadsheet-style formulas between facts.
- Scheduled automations and the inbox.

## Open questions (to settle before building)

1. ~~Manual-edit detection~~ **Resolved**: probe Album's text-change
   events first; announce-on-focus-loss as fallback.
2. ~~Announcement granularity~~ **Resolved**: one canvas-wide announcer
   with typed events (FactChanged, WidgetChanged).
3. ~~Core or UI for `AgentKnowledge`?~~ **Resolved: Core** (with the canvas
   lookup behind a globals guard, the gateway's established pattern), so
   headless code and the gateway share the same vocabulary — `AgentUnknown`
   lives there too.
