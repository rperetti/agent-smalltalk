# Architecture decision records

ADRs preserve decisions whose reasoning would otherwise be rediscovered from
debugging comments, old phase documents, or commit history. They describe why a
durable architectural choice was made; they are not implementation plans or
backlog items.

## When to write an ADR

Use an ADR when a decision:

- changes a trust, persistence, concurrency, or provider boundary;
- chooses one architectural approach over credible alternatives;
- introduces a constraint future contributors may otherwise remove as cruft;
- records a deliberately accepted trade-off likely to be questioned again;
- resolves a backlog item whose rationale should outlive its implementation.

Do not use an ADR for a local refactor, ordinary bug fix, feature checklist, or
unresolved idea.

## File convention

```text
NNNN-short-kebab-case-title.md
```

Numbers are assigned sequentially and never reused. Superseded ADRs remain in
the index and link to their replacement.

## Template

```markdown
# NNNN — Decision title

**Status:** proposed | accepted | superseded | deprecated
**Date:** YYYY-MM-DD
**Deciders:** names or roles
**Related backlog:** AS-NN

## Context

What forces and constraints require a decision?

## Decision

What are we choosing?

## Alternatives considered

What credible options were rejected, and why?

## Consequences

What becomes easier, harder, required, or deliberately unsupported?

## Revisit when

What evidence or change would justify reopening the decision?
```

## Index

No formal ADRs have been extracted yet. Strong candidates already documented
elsewhere include:

- image-closed automation semantics: record one miss, never catch up;
- the interactive listener's explicit enable flag rather than stale GUI-state
  detection;
- generated tools living in image-only packages rather than `src/`;
- the decision to postpone visible wiring while global reactions are adequate;
- the provider-neutral boundary proposed in backlog item AS-14.

Create ADRs when one of these decisions is next changed or materially relied
upon; avoid a mechanical history-writing exercise with no active use.
