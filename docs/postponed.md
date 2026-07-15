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

*Drafted as a full spec, postponed 2026-07-05.*

**What it was.** Drag from one object (a fact, a widget) to another; a visible
spline connects them and data flows along it — the vision's "draw a line from
the Email Inbox to the To-Do List" made real. Wires would be first-class
canvas objects (selectable, deletable, persistent), turning the canvas into a
runnable dataflow diagram. The money shot: drag a `#city` fact onto a blank
widget and watch it bind and track. (The full draft is in git history at
commit `4c44487`, as `docs/phase5_spec.md`.)

**Why postponed.**
- **No proven need.** The global announcer already gives full
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

## AS-03 — Persistence, recovery, and portable world migration

*Designed through repository review and discussion, postponed 2026-07-15.*

**What it was.** Replace the current collection of snapshots and partial
backups with explicit guarantees for saving, recovery, and moving a user's
living world to a newer platform image. The work began as one backlog item but
contains three different promises:

1. **Living-image evolution:** update platform classes in place while keeping
   generated classes and live instances.
2. **Exact recovery:** resume one world from a coherent checkpoint of its
   object memory and browsable source.
3. **Portable migration:** reconstruct the agent-owned world in a different
   image or platform version without treating the old image as the interchange
   format.

These promises should remain separate. `update.sh` is the ordinary first path:
it reloads platform source into the living image, runs deterministic migrations
against existing objects, verifies the result, and snapshots only after
success. A checkpoint is the high-fidelity fallback for that exact runtime. A
portable export is for a fresh-image transition, another machine, or recovery
when the old runtime can no longer be carried forward.

**Direction if resumed.** Build the work in three milestones: define the
persistence contract and state inventory; make checkpoint and restore coherent;
then add portable export/import. The first milestone should produce an ADR
before runtime behavior changes. AS-05 supplies the mutation boundary needed
to checkpoint a quiet world, while AS-15 later adds durable provenance and
rollback to the artifacts being moved.

A checkpoint should be an atomically published bundle rather than a loose image
copy. It should contain the `.image` and matching `.changes`, identify the
compatible VM and base sources, record platform and prompt revisions, enumerate
generated packages, and carry checksums plus a completion marker. Saving should
stage, verify, and only then publish the bundle. The canvas should distinguish
saved, unsaved, saving, and failed-save state.

A portable export should use a small, versioned product format. One candidate
is a `.agentworld` archive containing:

```text
manifest.json
world.json
packages/
attachments/
checksums.json
```

The manifest records the bundle-format version, stable export ID, compatible
platform range, platform and prompt revisions, package list, and hashes.
Generated behavior is exported as Tonel source. Logical state is plain,
validated data with stable object IDs and explicit type/schema versions; JSON
through the already-loaded `STONJSON` keeps parsing separate from class
materialization. Fuel may help with same-runtime graph transfer or as a
replaceable fast path, but a version-specific binary stream should not be the
only durable representation.

The portability boundary must account for live Smalltalk evolution rather than
assuming every agent change creates a new package:

| mutation | portable treatment |
|---|---|
| Recompiled method or reshaped agent-owned class | Export the final class shape and source, then restore its declared logical state. |
| References among facts, widgets, tools, and automations | Preserve stable object IDs and explicit relationships. |
| Subscriptions, processes, sockets, UI children, and other runtime machinery | Exclude and reconstruct through lifecycle hooks. |
| Patch to a platform or dependency method | Record the target, baseline revision, pre-change source hash, and replacement source; report a conflict if the target changed. |
| Mutation of an arbitrary global, singleton, or system object | Require a platform-owned export adapter or declare it checkpoint-only. |

This boundary is necessary because `AgentSandbox` can evaluate arbitrary
Smalltalk. No portable format can honestly preserve every possible mutation to
the image while remaining independent of that image. Agent-owned domain roots
can be portable; unclassified runtime state cannot.

Import is a deployment operation and imported code is executable. It should
therefore run against a disposable copy of the target image: validate bounds,
schema, and checksums; parse data without materializing arbitrary classes; run
platform-owned adjacent-version migrations; load Tonel; reconstruct objects and
relationships; reconnect lifecycle resources; restore automations disabled;
and verify behavior and browsable source. Only a verified staged pair may
replace the target world. Unknown executable artifact types and stale platform
patches fail closed rather than importing partially.

The in-image agent can inspect an unresolved artifact and propose a migration
or rebase in that staged world. The accepted result must become deterministic,
recorded source and pass the same checks before promotion. Recovery itself must
not require a model call, network access, provider availability, or another
nondeterministic generation.

**Why postponed.** Same-image platform updates already preserve the current
world, which covers the project's routine development path. A portable format
would commit the project to compatibility, migration, conflict, and import
security rules before there are real user worlds testing those rules. The
unrestricted evaluator also makes the portable boundary a product decision,
not a serializer selection. Implementing that surface now would displace work
on the model-context boundary and other existing-system guarantees.

**Accepted trade-off.** The current pre-request backup can miss unsaved work and
does not include the matching `.changes`; there is no supported portable
generated-world export; and a dependency or Pharo upgrade that requires a fresh
image has no automatic migration path. The `.image` and `.changes` pair remain
irreplaceable user state. Routine changes must use `update.sh`, not a fresh
build. Publication remains blocked by AS-29 while this trade-off is accepted.

**What would bring it back.** Resume AS-03 before publication; before a Pharo,
Bloc, or other dependency transition that cannot update the living image in
place; after a real loss or failed recovery; when a valuable world needs to
move between machines or platform versions; or when accumulated generated
artifacts make manual preservation credible enough to test the portability
contract. Start with the state inventory and recovery drill, not the archive
format.
