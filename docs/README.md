# Project documentation

The files under `docs/` are the project's source of truth for product direction,
current behavior, operational knowledge, and planned work. Planning lives in this
file-based system rather than in GitHub Issues; inbound issues and discussions
are triaged into it (see [CONTRIBUTING.md](../CONTRIBUTING.md)).

## Document map

| document | canonical responsibility |
|---|---|
| [vision.md](vision.md) | The north star: why the project exists and the future it is exploring. Aspirational unless a capability is also in the system specification. |
| [experiments.md](experiments.md) | Research questions, prior evidence, protocols, observations, limits, and the decisions they produced. |
| [system_spec.md](system_spec.md) | What is implemented and expected to work today. Change it in the same commit as behavior changes. |
| [backlog.md](backlog.md) | The single ordered register of actionable bugs, reliability work, security work, operations, architecture, and sufficiently understood features. |
| [ideas.md](ideas.md) | Product and feature possibilities that are not understood or validated well enough to order for implementation. |
| [postponed.md](postponed.md) | Ideas or designs that were seriously evaluated and consciously deferred, including what would bring them back. |
| [security.md](security.md) | The current trust model, authority boundaries, non-guarantees, and known security risks. |
| [operations.md](operations.md) | How to build, update, test, run, diagnose, back up, and recover the living image. |
| [warnings.md](warnings.md) | Assessed native-loader warning exceptions and their review triggers. |
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
        +-- known defect or understood outcome --> backlog candidate
        |
        `-- uncertain product hypothesis --------> experiment record
                                                     |
                                            prior evidence + protocol
                                                     |
                                              observation + decision
                                                     |
                                  backlog / ideas / postponed / direction
```

An evidence-backed platform technique still enters the backlog before it
changes behavior. Its item records the supporting result and the local
comparison required before the new behavior becomes the baseline for later
experiments. Implementation and verification then update the system
specification, operations, security reference, or an ADR as usual.

An idea can instead move to `postponed.md` when it has been evaluated but there
is a deliberate reason not to pursue it. When a backlog item is implemented and
verified, remove it from `backlog.md` rather than retaining a growing completed
archive. The lasting truth belongs in the system specification, supporting
reference document, tests, commit history, or an ADR.

The field schema, category vocabulary, and ordering rules that govern the
backlog live in `backlog.md` itself, under its `Conventions` section.

## Avoiding duplicated truth

- Current behavior belongs in `system_spec.md`, not the backlog.
- Hypotheses, protocols, observations, and research decisions belong in
  `experiments.md`.
- A desired behavior belongs in the backlog until it is implemented.
- Operating instructions belong in `operations.md`; backlog items describe how
  those instructions or mechanisms need to improve.
- Current risks and authority boundaries belong in `security.md`; remediations
  remain ordered in the backlog.
- Ideas are not promises. They become backlog items only when there is enough
  evidence to state an outcome and acceptance criteria.
- Create `docs/backlog/AS-NN-short-title.md` only when an item grows too large
  for the central register. Keep its summary and current rank, if applicable,
  in `backlog.md`.
