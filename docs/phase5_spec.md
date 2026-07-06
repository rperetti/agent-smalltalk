# Phase 5 Specification: Wiring — Connections You Can Draw

> **Status: DRAFT for discussion.**
>
> This is the phase I think follows most naturally from phase 4, but it is a
> real fork in the road — see "Why this phase (and the alternative)" below.
> If you'd rather take the agency branch (scheduled automations + the inbox),
> say so and I'll redraft; the parking lot keeps both.

## Goal

Phase 4 made facts and widgets *reactive* — but the reactivity is invisible,
buried in generated subscription code. Phase 5 makes it **visible and
user-composable**: you draw a line from one object to another, and data
flows along it. This is the vision's signature use case taking root —
"the user draws a visual line connecting an Email Inbox node to a To-Do List
widget; the agent writes the Smalltalk bridging them" ([vision.md](vision.md))
— and it promotes the parked "variables / visual wiring" idea
([ideas.md](ideas.md)) into a first-class capability.

The money shot: **drag from a `#city` fact sticky to a blank widget; the
agent wires them; the widget now shows — and tracks — your city, with a
visible spline proving the connection exists.**

## What this phase proves

1. **Connections are objects**: a wire between two widgets is itself a
   canvas citizen — visible, selectable, deletable, persistent — not hidden
   code.
2. **Drawing is programming**: a user gesture (drag from A to B) causes the
   agent to generate the binding, closing the loop between direct
   manipulation and code generation.
3. **The graph is legible**: at a glance you can see what feeds what — the
   canvas becomes a dataflow diagram that actually runs.

## Design

### AgentWire — the connection object

A wire connects a **source** (a fact, or a widget) to a **target** widget.

- Drawn as a spline (Bloc vector path) from source edge to target edge,
  re-routed when either endpoint moves (subscribes to their position, reusing
  the phase-4 announcer).
- Is an `AgentWidget`-family object: selectable, deletable (deleting the wire
  tears down the binding it created), persists in the image, has a `describe`
  (`wire: #city → GreetingWidget`) so the model sees connections in context.
- Holds the subscription it created, so removal cleanly unsubscribes (the
  phase-4 auto-unsubscribe contract).

### The wiring gesture

- A **connect handle** on each widget (small port, distinct from the resize
  grip): drag from it to another widget to start a wire. Drag ends on a
  target → a pending `AgentWire` is drawn and the agent is asked to bind them.
- Dragging from a **fact sticky's** handle wires a value; from a **tool
  widget's** handle wires that widget's changes.
- Uses **drag events** (the phase-3/4 lesson: bubbled moves get eaten by
  widget internals; drag events follow the originating element).

### Agent-generated binding

When a wire is completed, the gateway gets a scoped request describing the
two endpoints (like selection-scoped context, but for exactly the pair) and
the live objects bound to globals (`WireSource`, `WireTarget`). The crib
teaches the binding pattern: read the source via `AgentKnowledge`/accessor,
subscribe to its change announcement, update the target, `flashUpdated`.
The wire records the resulting subscription for teardown.

### Persistence & legibility

- Wires live on the canvas, so they survive save/reopen with everything else.
- Wires render *under* widgets (elevation floor) so they never intercept
  widget gestures.
- A wire whose endpoint is deleted removes itself (and posts a gray system
  message: "removed a dangling wire").

## Acceptance script

1. A `#city` fact and an empty/placeholder widget on the canvas. **Drag from
   the fact's connect handle to the widget.** The agent binds it; the widget
   shows the city; a spline connects them. *(Money shot.)*
2. Edit the `#city` sticky by hand → the wired widget updates and the spline
   flashes.
3. Drag both endpoints apart → the spline re-routes to follow.
4. Wire a counter to a "doubler" widget: counter changes → doubler tracks,
   live, over the wire.
5. Delete the wire → the binding is torn down (target stops tracking), the
   spline vanishes, no error.
6. Save, quit, reopen → wires and their bindings intact and still live.

## Non-goals (parked, see [ideas.md](ideas.md))

- Transformations *on* the wire (map/filter/formula between source and
  target) — v1 wires pass the value through; computed edges are a later step.
- Many-to-one fan-in with combination logic (sum of N wired sources) —
  phase-3 lasso already covers the explicit-selection version.
- Local/temporary variables and scope overrides.
- Scheduled automations and the inbox (the agency branch).
- Preferences and theming.

## Open questions (to settle before building)

1. **Connect handle vs. modifier-drag.** A dedicated port on each widget is
   discoverable but adds chrome; alternatively, a modifier (e.g. Alt+drag
   from a widget) starts a wire with no chrome. Recommendation: dedicated
   handle — discoverability wins for a novel gesture, and we already have the
   resize grip as precedent.
2. **Does the agent bind, or does a fixed mechanism?** Agent-generated
   binding is flexible (any source→target semantics) but slower and variable;
   a fixed "mirror the source's value/announcement" mechanism is instant and
   reliable for the common case. Recommendation: fixed mechanism for
   fact→widget and widget→widget value mirroring, agent only when the user
   asks for non-trivial semantics ("wire these but show it in Fahrenheit").
   This keeps the money shot instant.
3. **Wire directionality / cycles.** One-way (source→target) only in v1?
   Recommendation: yes — one-way, and refuse a wire that would form a cycle
   (post a system message), deferring bidirectional/reactive-loops.

## Why this phase (and the alternative)

Wiring is the tightest continuation of phase 4: it takes the reactive
substrate just built and hands it to the user as a gesture, and it's the
vision's most-cited concrete example. It's also visually striking — the best
kind of money shot.

The alternative is **agency**: scheduled automations + the actionable inbox
that the gray system messages already seeded. That's a bigger thesis leap
(the system acts without being asked) but needs its own trust/interaction
design pass (what triggers runs, budgets, how to stop a runaway) and is less
continuous with what just shipped. I'd hold it as phase 6 unless you feel the
pull now.
