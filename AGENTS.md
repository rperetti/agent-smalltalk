# AGENTS.md

Guidance for code agents and tools working in this repo. Humans: start with the
[README](README.md) and [CONTRIBUTING.md](CONTRIBUTING.md).

## Scope and collaboration

This guide applies throughout the repository. Treat the checkout as shared:
inspect `git status` before editing, preserve unrelated changes, and do not
discard, overwrite, stage, or commit another contributor's work. Do not edit
generated or ignored runtime artifacts such as `pharo/`, `logs/`, image backups,
or `.changes` files.

For a non-trivial change, use the [documentation map](docs/README.md) to find
the document that owns the relevant current behavior. The vision and backlog
describe direction and planned work; they are not evidence that a capability
exists today.

## Writing voice

Write all prose and documentation in the repo's voice: concise, precise,
technically accurate, honest about tradeoffs, warm but not marketing. Assume a
competent reader; cut hype, filler, and repetition. The full guide, with
examples, is [docs/STYLE.md](docs/STYLE.md) — follow it for every doc you touch.

## Versioned source vs. image state

The one thing to internalize first: `src/` (hand-maintained Tonel packages) is
the versioned source of truth; `pharo/Agent.image` is a generated build product
that holds the living world. Platform implementation changes belong in `src/`;
prose and product documentation belong in their owning tracked files (usually
under `docs/`), and the base prompt's versioned source is `prompts/system.md`.
Never treat a change made in the image as a contribution.

Never `./build.sh` against a living image you care about — it discards that
world; use `./update.sh` to reload `src/` changes while preserving state. Do
not run `./update.sh`, `./run.sh`, or the localhost `/eval` endpoint as routine
automated validation: each can mutate or activate the shared living world.
Before a command touches a living image, read the operations guide end to end.
Use live-image commands only when the task needs that integration and their
effects are understood. Details in
[docs/operations.md](docs/operations.md#state-model).

## Working habits

- Add or update deterministic tests with platform behavior, then run
  `./verify-all.sh` before committing platform changes. It is free and does not
  open or mutate `Agent.image`. `./evaluate.sh` exercises the real model and
  costs money; use it when gateway, generation, or base-prompt behavior changes.
- Testing is native-only: verify with the repository's local Pharo VM through
  `./test.sh` or `./verify-all.sh`. Do not use Docker or a container as a test
  fallback or verification gate.
- Keep the native test suite working. If it fails or stops during a session,
  investigate and fix the failure before handoff; do not bypass it or report
  unrelated checks as a substitute.
- Treat `prompts/system.md` as executable product behavior: review it like code,
  keep its promises aligned with the loaded dependency closure, and verify any
  changed generation behavior at the appropriate gate.
- Keep the docs in sync in the same commit as the change: behavior →
  `docs/system_spec.md`, commands/recovery → `docs/operations.md`, authority/data
  flow → `docs/security.md`, planned work → `docs/backlog.md`.
- Planning is file-based under `docs/`, not tracked in GitHub Issues. The
  [documentation map](docs/README.md) explains which document owns which truth.

## Safety

There is no sandbox: generated Smalltalk executes immediately in the running
image with full authority over the machine, and everything on the canvas is sent
to the Anthropic API on every request. See [docs/security.md](docs/security.md).
