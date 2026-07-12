# Project documentation

The files under `docs/` are the project's source of truth for product direction,
current behavior, operational knowledge, and planned work. Planning lives in this
file-based system rather than in GitHub Issues; inbound issues and discussions
are triaged into it (see [CONTRIBUTING.md](../CONTRIBUTING.md)).

## Document map

| document | canonical responsibility |
|---|---|
| [vision.md](vision.md) | The north star: why the project exists and the future it is exploring. Aspirational unless a capability is also in the system specification. |
| [system_spec.md](system_spec.md) | What is implemented and expected to work today. Change it in the same commit as behavior changes. |
| [backlog.md](backlog.md) | The single ordered register of actionable bugs, reliability work, security work, operations, architecture, and sufficiently understood features. |
| [ideas.md](ideas.md) | Product and feature possibilities that are not understood or validated well enough to order for implementation. |
| [postponed.md](postponed.md) | Ideas or designs that were seriously evaluated and consciously deferred, including what would bring them back. |
| [security.md](security.md) | The current trust model, authority boundaries, non-guarantees, and known security risks. |
| [operations.md](operations.md) | How to build, update, test, run, diagnose, back up, and recover the living image. |
| [STYLE.md](STYLE.md) | The writing voice for all prose and documentation, for humans and code agents alike. |
| [adr/](adr/README.md) | Durable architectural decisions and the reasoning behind them. |

The repository [README](../README.md) remains the newcomer-facing introduction
and quick start, and [CONTRIBUTING.md](../CONTRIBUTING.md) covers the
source-versus-image-state model and the testing, build, and documentation habits
for changing the project. The base prompt in
[`prompts/system.md`](../prompts/system.md) is executable product behavior and
should be reviewed and tested like code.

## Work-item lifecycle

```text
Observation or idea
        |
        v
Enough evidence and a proposed outcome
        |
        v
Backlog candidate
        |
        v
Ordered into Now / Next / Later
        |
        v
Implemented and verified
        |
        v
System spec, operations, security, or ADR updated
```

An idea can instead move to `postponed.md` when it has been evaluated but there
is a deliberate reason not to pursue it. When a backlog item is implemented and
verified, remove it from `backlog.md` rather than retaining a growing completed
archive. The lasting truth belongs in the system specification, supporting
reference document, tests, commit history, or an ADR.

## Backlog fields

Each actionable item has a stable `AS-NN` identifier and records:

- **status** — `candidate`, `ready`, `in-progress`, `blocked`, `done`,
  `postponed`, or `superseded`;
- **categories** — what kind of work it is;
- **priority** — urgency/impact independent of its current rank;
- **effort** — a rough `S`, `M`, or `L` comparison, not an estimate;
- **dependencies** — work that should land first;
- **problem and argument** — why the item exists;
- **proposed outcome** — the intended result without over-prescribing the
  implementation;
- **acceptance criteria** — observable evidence that the work is complete.

The initial category vocabulary is deliberately small:

- `bug`
- `security`
- `reliability`
- `operations`
- `architecture`
- `product`
- `feature`
- `ux`
- `testing`
- `documentation`
- `performance`
- `maintenance`

An item can have multiple categories. Category answers "what kind of work is
this?" Priority answers "how urgent is it?" Rank answers "what is our current
agreed order?" These are intentionally separate, except that the `bug` category
has precedence in rank: every item categorized as a bug ranks ahead of every
non-bug, regardless of priority.

## Collaborating on ordering

The `Now`, `Next`, and `Later` tables at the top of `backlog.md` are the planning
surface. Reordering those rows should be a small, explicit change; detailed
entries do not need to move or be rewritten.

When ordering work, use these default decision drivers:

1. Put all bugs before all non-bugs, independently of priority.
2. Prevent unauthorized execution or loss of the living world.
3. Make existing promises reliable before widening them.
4. Improve observability and verification.
5. Strengthen the system's ability to evolve without accumulating invisible
   damage.
6. Add new product surface when it tests an important product hypothesis.

Bug-first ordering is invariant. The remaining drivers are defaults, not a
permanent scoring formula; new evidence can justify a different order within
the bug and non-bug groups. `scripts/check-backlog-order.sh`, included in the
deterministic verification path, checks this invariant along with contiguous
ranks and agreement between planning rows and detailed entries.

## Avoiding duplicated truth

- Current behavior belongs in `system_spec.md`, not the backlog.
- A desired behavior belongs in the backlog until it is implemented.
- Operating instructions belong in `operations.md`; backlog items describe how
  those instructions or mechanisms need to improve.
- Current risks and authority boundaries belong in `security.md`; remediations
  remain ordered in the backlog.
- Ideas are not promises. They become backlog items only when there is enough
  evidence to state an outcome and acceptance criteria.
- Create `docs/backlog/AS-NN-short-title.md` only when an item grows too large
  for the central register. Keep its summary and rank in `backlog.md`.
