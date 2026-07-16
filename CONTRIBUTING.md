# Contributing to agent-smalltalk

This is a research prototype, not a product. The useful contributions are small,
well-argued changes that keep the living environment coherent. This guide covers
the one thing to understand first — the split between source and image state —
then the testing, build, and documentation habits that keep the project safe to
work on.

New here? Read the [README](README.md) and the
[documentation map](docs/README.md), then [docs/operations.md](docs/operations.md)
end to end before you run anything that touches a living image.

## First: `src/` vs. image state

agent-smalltalk has two kinds of state, and confusing them is the main way to
lose work.

- **Platform source — `src/`.** Hand-maintained [Tonel](https://github.com/pharo-vcs/tonel)
  packages: the gateway, sandbox, canvas, widgets, scheduler, and tests. This is
  the reproducible source of truth and the only thing under version control.
  Packages: `AgentSmalltalk-Core`, `AgentSmalltalk-UICompatibility`,
  `AgentSmalltalk-UI`, `AgentSmalltalk-Tests`, `AgentSmalltalk-UITests`, and
  `BaselineOfAgentSmalltalk`.
- **Living-world state — `pharo/Agent.image`.** The generated widget/tool/
  automation classes, live instances, facts, notes, canvas positions, and user
  edits that the agent and user build up at runtime. The image is a *build
  product*; it is gitignored and never committed.

**Contributions change `src/` only.** A change made by editing a running image
is invisible to everyone else until it is written back into `src/`. Conversely,
rebuilding an image from `src/` (`./build.sh`) discards a living world, so never
do that against an image you care about — use `./update.sh` to reload your
`src/` changes into a living image without destroying its state.

See [docs/operations.md](docs/operations.md#state-model) for the full state
model, update paths, and their current limitations.

## Development loop

1. Edit the Tonel packages under `src/`. Match the surrounding style: naming,
   comment density, and Pharo idiom of the package you are in.
2. Add or update deterministic tests in `AgentSmalltalk-Tests` /
   `AgentSmalltalk-UITests` alongside the behavior you change.
3. Run `./test.sh` — it builds a disposable clean image and runs SUnit without
   ever opening `Agent.image`.
4. To try your change interactively, run `./update.sh` to reload `src/` into the
   living image (world preserved), *not* `./build.sh`.

Editing Smalltalk is most comfortable from inside a Pharo image with a real
System Browser. If you develop that way, remember step 1's corollary: the change
does not exist for the project until it is filed out to `src/` and committed.

## Testing and verification

| command | what it proves | touches `Agent.image`? |
|---|---|---|
| `./test.sh` | SUnit on a fresh disposable image | no |
| `./verify-all.sh` | the full deterministic release gate: SUnit + automation smoke + paid-smoke **syntax** checks | no |
| `./evaluate.sh` | paid model evaluations in fresh images (needs `ANTHROPIC_API_KEY`, costs money) | no |

Every change to platform source should keep `./verify-all.sh` green. It does not
make paid provider calls, so it is safe and free to run often. `./evaluate.sh`
exercises the real model and is intentionally separate because it costs money;
run it when you touch the gateway, the base prompt, or generation behavior. See
[docs/operations.md](docs/operations.md#verification-and-evaluation-gates) for
what each smoke script gates.

When native compiler or package warnings change, assess the warning before
committing. The native gate rejects unassessed warnings; an exceptional warning
needs an ID, severity, impact, and review trigger in
[docs/warnings.md](docs/warnings.md), plus a matching loader marker.

The suite is strongest for deterministic object behavior and does **not** prove
the living image's full snapshot/recovery path — exercise real runtime behavior
by hand when your change affects it.

## Documentation responsibilities

Documentation is part of the change, not a follow-up. `docs/` is the project's
source of truth, so keep it in sync in the *same commit*:

- **`docs/system_spec.md`** — update whenever observable behavior changes. It
  records what works today.
- **`docs/operations.md`** — update if commands, state, diagnostics, backup, or
  recovery behavior changed.
- **`docs/security.md`** — update if authority boundaries or data flow changed.
- **`docs/backlog.md`** — the ordered register of actionable work. Remove an
  item when it is implemented and verified rather than keeping a completed
  archive; the lasting truth belongs in the spec, tests, or an ADR. Bug-first
  ordering is invariant and enforced by `scripts/check-backlog-order.sh`.
- **`docs/adr/`** — record durable architectural decisions and their reasoning.
- **`prompts/system.md`** — the base prompt is executable product behavior.
  Review and test it like code.

Write documentation in the repo's voice — concise, precise, honest, no marketing
or filler. The full guide is [docs/STYLE.md](docs/STYLE.md). The
[documentation map](docs/README.md) explains which document owns which kind of
truth and how work items move from idea to implemented.

## Ways to contribute

Code is not the only contribution that counts. All of these are welcome:

- **Code** — fork and open a pull request (see below).
- **Bug reports and feature requests** — open a GitHub issue.
- **Ideas and brainstorming** — open an issue or discussion; a half-formed idea
  is fine.

## Submitting code changes

Contributors open a **pull request** from a fork. (The maintainer works directly
on `main`; you don't need to.)

- Keep changes small and focused, with a clear argument for why they exist.
- Write imperative commit subjects (e.g. "Reject invented fact writes during
  gateway tool execution"), matching the existing history.
- Run `./verify-all.sh` before you push platform changes.
- This project was built as a human–agent collaboration; when a change was
  co-authored with an AI model, record it with a `Co-Authored-By` trailer, as
  the existing history does.

## Reporting bugs and proposing work

Open a GitHub issue for a bug, feature request, or idea. Planning itself is
file-based, not tracked in issues: the maintainer triages an issue into a
[backlog](docs/backlog.md) item with a stable `AS-NN` id, or into
[docs/ideas.md](docs/ideas.md) when it is not yet ready to order. Actionable work
follows the work-item lifecycle in the
[documentation map](docs/README.md#work-item-lifecycle): an observation needs
enough evidence, a proposed outcome, and acceptance criteria before it is ready
to implement.

## A safety reminder

There is no sandbox: the agent writes Smalltalk and executes it immediately in
the running image with full authority over the image and, through it, your
machine. Everything on the canvas is sent to the Anthropic API on every request.
Develop somewhere you are comfortable handing a coding agent the keys, and never
put secrets or sensitive data on the canvas. The current trust model is in
[docs/security.md](docs/security.md).
