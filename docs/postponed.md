# Postponed

Ideas we drafted or worked out in real detail, then **consciously deferred**.
Different from [ideas.md](ideas.md) (product and feature possibilities not yet
ready to order): each entry here was considered seriously, and each records
*why* it was set aside and *what would bring it back*. Nothing here is rejected
— it's waiting for a reason to exist.

Actionable work, including bugs and reliability/security/operations changes,
lives in the ordered [backlog](backlog.md). See the
[documentation map](README.md) for the complete lifecycle.

---

## Wiring — user-drawn connections between canvas objects

*Drafted as a full phase spec, postponed 2026-07-05.*

**What it was.** Drag from one object (a fact, a widget) to another; a visible
spline connects them and data flows along it — the vision's "draw a line from
the Email Inbox to the To-Do List" made real. Wires would be first-class
canvas objects (selectable, deletable, persistent), turning the canvas into a
runnable dataflow diagram. The money shot: drag a `#city` fact onto a blank
widget and watch it bind and track. (The full draft is in git history at
commit `4c44487`, in the then-current `docs/phase5_spec.md`.)

**Why postponed.**
- **No proven need.** Phase 4's global announcer already gives full
  reactivity. Wiring only makes that reactivity *visible and composable* —
  valuable, but a solution ahead of its problem. We don't yet know where the
  canvas is going, and drawing this conclusion now is premature.
- **Heavy machinery for a nicety.** Splines, connect-handles, hit-testing,
  wire lifecycle, cycle detection — significant UI surface to maintain,
  justified only once someone actually hits the wall global reactivity leaves.
- **Keep it simple.** For now everything stays global (the canvas-wide
  announcer, `AgentKnowledge`, the update listener). Simpler to reason about
  and to build on.

**Accepted trade-off.** The global announcer is checked by every subscriber
on every announcement — an O(subscribers) cost. At current scale (a handful
of widgets) this is invisible, and optimizing it now would be guessing at a
bottleneck that doesn't exist. Revisit only if profiling on a genuinely
populated canvas shows it.

**What would bring it back.** A concrete use case where global reactivity is
insufficient or illegible — e.g. the user can't tell what feeds what on a
busy canvas, or needs per-connection transforms (show this value in
Fahrenheit *on the way* to that widget), or wants to compose flows the agent
can't infer from context alone. When that friction is real, the draft is
ready to resume.
