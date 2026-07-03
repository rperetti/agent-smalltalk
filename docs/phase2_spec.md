# Phase 2 Specification: Knowledge on the Canvas

> **Status: ACHIEVED (2026-07-03).** Headless acceptance green
> (`scripts/smoke-facts.st`: remember, use-without-asking, keyed update,
> implicit capture — plus the model retuning a dependent clock widget
> unprompted when the city changed) and the visual pass verified by hand.
> Original decisions: sticky notes, not a single knowledge card; implicit
> capture on by default; preferences and variables parked — see
> [ideas.md](ideas.md).

## Goal

The agent remembers durable facts the user states — name, city, anything
worth keeping — as **visible sticky-note objects on the canvas**. Memory you
can see, edit by typing, and forget by deleting. No hidden store: the canvas
*is* the memory, and the existing dynamic-context mechanism *is* the
retrieval.

This is the "Persistent Assistant" use case from
[original_spec.md](original_spec.md), built on the Object Uniformity tenet:
a fact is an object like everything else.

## Design

### AgentFact — the sticky (hand-written, not generated)

A small, visually distinct widget (pale yellow, smaller than tool widgets,
~180×100):

- **body**: freeform editable text (`ToAlbum`), e.g. "Rodrigo lives in Porto
  Alegre". Editing the text *is* editing the memory.
- **key**: optional symbol (`#city`, `#userName`) giving the fact an identity
  for updates — one sticky per key, ever.
- **delete affordance** (close button or Esc-style gesture): forgetting is a
  physical act.
- `describe` renders `fact[city]: Rodrigo lives in Porto Alegre`.
- Facts are **instances, not generated classes** — the model creates/updates
  them with plain expressions (`AgentFact key: #city body: '...'`), which is
  far cheaper and more reliable than class generation.

### Context rendering

`AgentCanvas contextDescription` splits into two sections: `## Known facts`
(all stickies, always included — dozens of facts cost a few hundred tokens)
and `## Widgets on the canvas` (as today). A dedicated facts section reads
better for the model than facts interleaved with tool widgets.

### Capture policy (crib sheet)

- **Implicit and loud**: whenever the user states a durable fact — even in
  passing, mid-request ("make a weather widget, I'm in Lisbon") — create or
  update the sticky as a side effect. The sticky visibly appearing on the
  canvas is the announcement and the consent mechanism: the user sees what
  was remembered and can flick it away.
- **Update, don't duplicate**: existing facts (with keys) are listed in
  context; a fact with the same key is updated in place ("I moved to Madrid"
  edits the `#city` sticky).
- **Use facts silently**: when a request depends on a known fact, just use
  it. When it depends on an unknown one, ask — and remember the answer.

### Placement

New stickies appear in a loose stack near the top-left corner (slight offset
per sticky), draggable like everything else. A proper "memory corner" and
clustering belong to phase 3's spatial features — an accumulating cloud of
stickies is exactly what will make that phase necessary.

## Acceptance script

1. **"Remember that I live in Porto Alegre"** → a sticky appears with the
   fact; the answer confirms it.
2. **"Make me a widget showing the current time in my city"** → built
   correctly with no clarifying question (the fact arrived via context).
3. Save, quit, reopen. **"What city do I live in?"** → answered from the
   canvas.
4. Edit the sticky's text to Madrid. The next city-dependent request uses
   Madrid.
5. Delete the sticky. The next city-dependent request has to ask. Forgetting
   works.
6. Implicit capture: **"make a greeting widget — by the way, my name is
   Rodrigo"** → a `#userName` sticky appears unprompted and the greeting
   uses the name.
7. Dedup: state a new city twice in different words → still exactly one
   `#city` sticky, holding the latest value.

## Non-goals (parked, see [ideas.md](ideas.md))

- Facts as live variables wired into widgets (`AgentKnowledge at: #city`,
  locals, overrides) — the key on a sticky is deliberately just an identity
  for updates in this phase.
- Preferences/settings as scoped knowledge; canvas and widget theming.
- Documents/PDFs as knowledge; embedding search (unnecessary below hundreds
  of facts).

## Honest caveat

Facts ride the system prompt, so everything remembered is sent to the
Anthropic API on every request. Inherent to the architecture; worth knowing.
