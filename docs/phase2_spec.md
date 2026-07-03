# Phase 2 Specification: The Canvas Becomes the Context Window

> **Status: DRAFT for discussion.**

## Goal

Prove the second core thesis of [original_spec.md](original_spec.md): **spatial
arrangement is context management**. The user selects widgets by drawing around
them, and the agent's context is exactly what's selected — including live
references, so generated code can *operate on* the selected objects, not just
read about them.

Demo 1 proved English → living widget. Phase 2 proves widgets → material for
the next request.

## What phase 2 proves

1. **Selection is the context window**: with many widgets on the canvas, a
   request about "these" sees only the lassoed ones — verifiable in the
   gateway log.
2. **Live references cross the bridge**: the model can generate code that
   holds onto the actual selected widget objects (e.g. a TotalWidget that sums
   three selected counters and stays connected to them).
3. **The canvas is navigable space**: pan and zoom make room for enough
   widgets that context selection *matters*.
4. **The world survives tooling upgrades**: our own code reloads into the
   living image without destroying existing widgets.

## Workstreams

### 1. Navigable canvas (pan & zoom)

- Drag on empty background pans the content element; scroll/pinch zooms
  around the cursor (Bloc transformations on the content element).
- Widget dragging, summoning under cursor, and spotlight positioning keep
  working under transform (summon position maps through the inverse
  transform).

### 2. Lasso selection

- Drag on empty background with a modifier (or a mode toggle) draws a
  selection rectangle; widgets intersecting it become **selected** (visible
  highlight, e.g. accent border).
- Click on empty canvas clears selection. Selection state lives on
  `AgentCanvas` (`selectedWidgets`).

### 3. Selection-scoped requests with live references

The heart of the phase. When a selection exists and the user submits a
spotlight request:

- The dynamic context lists **only the selected widgets**, in richer form:
  class name, `describe`, instance-variable names, and the selectors of the
  generated class (cheap, high-signal).
- The gateway binds the selected objects to well-known globals before the
  run: `Selection1`, `Selection2`, ... (and `SelectionAll`, an Array). The
  crib documents them: generated code references live objects directly, e.g.
  `TotalWidget new watch: SelectionAll`.
- With no selection, behavior stays as today (all widgets, describe-only).

### 4. Reload without losing the world

- `./update.sh`: runs the Metacello load of `src/` **against the existing
  image** (no pristine copy) and saves. Our tooling classes recompile in
  place; generated widget classes and live instances are untouched.
- `./build.sh` remains for genuinely fresh starts.
- The sandbox backup rotation covers the failure case.

## Acceptance script

1. Summon six widgets; pan and zoom to arrange them in two clusters.
2. Lasso three counter widgets. Spotlight: **"make a widget that shows the sum
   of these counters, with a Refresh button."** The new widget appears,
   reads the three live counters through `SelectionAll`, and Refresh tracks
   their changing values. The gateway log shows only the three selected
   widgets in the system prompt.
3. Click a counter up a few times; Refresh on the total reflects it.
4. With nothing selected, a request still sees the full canvas (as today).
5. Edit a tooling method in `src/` (e.g. a status string), run `./update.sh`,
   reopen: the change is live AND every widget from steps 1–3 is still there,
   still working. *This is the image-as-world tenet finally honored by our
   own tooling.*
6. Save, quit, reopen: clusters, selection highlight gone (selection is
   transient), widgets and the total's live links intact.

## Non-goals (deferred, not rejected)

- Semantic clustering, force-directed layout, camera automation, wormholes,
  breadcrumbs (the "spatial gardener" — needs a populated canvas to be worth
  anything, which phase 2 creates).
- Direct manipulation rewriting source.
- Multiplayer; file/PDF ingestion; capability sandboxing.

## Open questions (to settle before building)

1. **Live-update semantics for derived widgets**: is a Refresh button enough
   for phase 2, or do we want the total to update automatically (polling on
   the space pulse vs. widgets announcing changes)? Recommendation: Refresh
   button now; announcements are a phase 3 idea (it starts the "visual
   programming" thread from the original spec).
2. **Selection ergonomics**: modifier-drag lasso vs. a selection-mode toggle
   button? Recommendation: modifier-drag (Shift), no mode state.
3. **Should `SelectionN` globals persist after the request?** Recommendation:
   yes, until the next selection — cheap continuity ("now make them all red").
