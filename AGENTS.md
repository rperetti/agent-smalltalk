# AGENTS.md

Guidance for code agents and tools working in this repo. Humans: start with the
[README](README.md) and [CONTRIBUTING.md](CONTRIBUTING.md).

## Writing voice

Write all prose and documentation in the repo's voice: concise, precise,
technically accurate, honest about tradeoffs, warm but not marketing. Assume a
competent reader; cut hype, filler, and repetition. The full guide, with
examples, is [docs/STYLE.md](docs/STYLE.md) — follow it for every doc you touch.

## Source vs. image state

The one thing to internalize first: `src/` (hand-maintained Tonel packages) is
the versioned source of truth; `pharo/Agent.image` is a generated build product
that holds the living world. Contributions change `src/` only. Never `./build.sh`
against a living image you care about — it discards that world; use `./update.sh`
to reload `src/` changes while preserving state. Details in
[docs/operations.md](docs/operations.md#state-model).

## Working habits

- Run `./verify-all.sh` before committing platform changes; it is free (no paid
  model calls). `./evaluate.sh` exercises the real model and costs money.
- Keep the docs in sync in the same commit as the change: behavior →
  `docs/system_spec.md`, commands/recovery → `docs/operations.md`, authority/data
  flow → `docs/security.md`, planned work → `docs/backlog.md`.
- Planning is file-based under `docs/`, not tracked in GitHub Issues. The
  [documentation map](docs/README.md) explains which document owns which truth.

## Safety

There is no sandbox: generated Smalltalk executes immediately in the running
image with full authority over the machine, and everything on the canvas is sent
to the Anthropic API on every request. See [docs/security.md](docs/security.md).
