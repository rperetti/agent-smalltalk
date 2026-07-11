# Operations

How to build, update, test, run, diagnose, back up, and recover Agent Smalltalk.
This describes current behavior. Planned improvements belong in the
[backlog](backlog.md).

## State model

Agent Smalltalk has two different kinds of source and state:

- **Platform source:** hand-maintained Tonel packages under `src/`. This is the
  reproducible source of truth for the gateway, canvas, runtime, and tests.
- **Living-world state:** generated widget/tool/automation classes, live
  instances, facts, notes, positions, histories, and user edits stored in
  `pharo/Agent.image` with source history in its matching `.changes` file.

`build.sh` creates a new world from platform source. `update.sh` reloads platform
source into the existing world. Confusing those operations is the main
operational hazard.

## Prerequisites

The currently documented local setup is Pharo 13 on macOS/Apple Silicon:

1. Download `pharoImage-arm64.zip` and
   `pharo-vm-Darwin-arm64-stable.zip` from
   `https://files.pharo.org/get-files/130/`.
2. Unzip the image under `pharo/` and the VM under `pharo/vm/`.
3. Export `ANTHROPIC_API_KEY` for real gateway requests.

`build.sh` and `test.sh` accept `PHARO_VM` and `PHARO_PRISTINE` overrides, which
are also the path for other supported local arrangements. `run.sh` and
`update.sh` currently use the macOS bundle path directly.

## Command summary

| command | purpose | effect on living world |
|---|---|---|
| `./build.sh` | Build a fresh full image from pristine Pharo and `src/`; run tests before replacement by default. | Replaces the target world after success. Existing default target is backed up first. |
| `./build.sh core` | Build gateway/sandbox/core tests without Bloc UI. | Creates/replaces the requested target image. |
| `./build.sh --output /tmp/Review.image` | Build a disposable full image at another path. | Does not replace `pharo/Agent.image`. |
| `./update.sh` | Reload platform packages into the living image. | Preserves generated classes and canvas state; backs up the image first. |
| `./test.sh` | Build a disposable pristine image and run the project SUnit suites. | Never opens or changes `pharo/Agent.image`. |
| `./run.sh` | Open the Agent canvas. | Opens the living image and enables interactive session services. |

## Fresh build

`build.sh`:

1. Locates the VM, pristine image, matching `.changes`, and optional `.sources`.
2. Creates a temporary build root and isolated `HOME`.
3. Links `src/`, `prompts/`, and the shared `pharo-local` dependency cache.
4. Loads the selected Metacello group into a copied pristine image.
5. Runs `scripts/run-tests.st` unless `--no-verify` was requested.
6. Backs up an existing output image and `.changes` unless `--no-backup` was
   requested.
7. Moves the verified staged image and `.changes` into the output path.

Use a fresh build for dependency changes, a deliberate factory reset, or an
independent verification image. Use `update.sh` for routine platform changes to
the living world.

## Living-image update

`update.sh` has two delivery paths:

- If a process using `Agent.image` is detected, it posts to the interactive
  image's loopback `POST /update` endpoint on port 8807.
- Otherwise it loads `scripts/update.st` headlessly into the image file.

`AgentUpdater` reloads the five platform packages with Tonel diff semantics,
runs canvas migrations, and posts a keyed system message. The interactive path
performs migration on the UI thread when possible.

Current limitations are tracked by
[AS-01](backlog.md#as-01--authenticate-or-remove-the-local-evaluator) and
[AS-02](backlog.md#as-02--make-live-updates-verifiable-and-atomic): the local
endpoint is unauthenticated, sentinel verification is not a complete revision
proof, and the live path can snapshot before endpoint-level verification.

Until AS-02 is resolved:

- run `./test.sh` before updating important living worlds;
- keep the pre-update backup;
- inspect the update system message and behavior after a live update;
- treat a failed live update as potentially partial in memory;
- do not save a failed live-update session over the known-good backup.

## Testing

`./test.sh` creates a disposable image, loads the pinned production dependency
graph and all project packages, then runs the suite enumerated in
`scripts/run-tests.st`.

The suite is strongest for deterministic object behavior: gateway tool
plumbing with a fake transport, sandbox results and timeouts, fact/note/context
behavior, selection math, scheduler timing, histories, widget lifecycle, and
tool cards. It does not make paid provider calls or prove the living image's
full snapshot/recovery path.

The full build's production UI closure is explicit in
`BaselineOfAgentSmalltalk` and `scripts/load-all.st`. It includes the canvas
renderer, Bee theme, and the Toplo Album, Label, Button, TextField, Checkbox,
and ProgressBar vocabulary promised to generated widgets. Upstream tests,
examples, demos, and developer tools are excluded and are guarded by
`AgentDependencyLoadTest`.

### Upstream UI development

When investigating or upgrading Bloc/Toplo itself, start with a disposable
image, never the living `pharo/Agent.image`, then deliberately load the full
upstream graph:

```bash
./build.sh --output /tmp/Agent-upstream-dev.image --no-verify --no-backup
pharo/vm/Pharo.app/Contents/MacOS/Pharo --headless /tmp/Agent-upstream-dev.image \
  st scripts/load-upstream-development.st
```

`scripts/load-upstream-development.st` adds the upstream test/example/tool
surface at the same pinned revisions. It is intentionally outside all normal
build, test, and verification paths.

### Dependency-load measurement

On 2026-07-11, clean `build.sh --no-verify` runs from otherwise identical
temporary workspaces and empty dependency caches produced:

| metric | broad upstream defaults | production closure |
|---|---:|---:|
| build duration | 100.15 s | 93.28 s |
| visual-stack packages in image | 146 | 71 |
| upstream test/example/demo/dev packages | 48 | 0 |
| upstream undeclared-reference warnings | 365 | 82 |
| image size | 109 MiB | 95 MiB |
| matching `.changes` size | 17 MiB | 13 MiB |
| dependency cache (`iceberg` + `package-cache`) | 100.8 MiB | 91.0 MiB |

## Verification and evaluation gates

`./verify-all.sh` is the local release signal. It runs SUnit, the deterministic
automation vertical smoke, and parses every paid smoke script without sending a
provider request. It never opens or mutates `Agent.image`.

`./evaluate.sh` is intentionally separate. It requires `ANTHROPIC_API_KEY`,
runs each named provider evaluation in a fresh disposable image, and fails on
the first semantic failure. To run one evaluation rather than the full suite:

```bash
./evaluate.sh fact-widget
```

Each paid run appends a JSON line to `logs/provider-evaluations.jsonl` with
model, prompt revision, request rounds, latency, repair attempts, exact token
usage, an explicit cost-unavailable marker (the provider response does not
return billed USD), outcome, and check-specific details.

| script | model/API call | role |
|---|---:|---|
| `smoke-automations.st` | no | Deterministic automation vertical slice with a real pass/fail exit. |
| `verify-provider-smoke-syntax.st` | no | Parses every paid script as part of `verify-all`. |
| `smoke-fact-widget.st` | yes | Same-request fact-backed weather widget gate. |
| `smoke-widget.st` | yes | Counter creation and real instance increment gate. |
| `smoke-modify.st` | yes | Live modification/state-preservation gate. |
| `smoke-textfield.st` | yes | Text-control and reverse-logic generation gate. |
| `smoke-facts.st` | yes | Fact capture/replacement and fact-widget gate. |
| `smoke-tools.st` | yes | Reusable-tool creation/context/reuse gate. |
| `smoke-selection.st` | yes | Selection-scoped live-reference gate. |
| `smoke-reactive.st` | yes | Fact and widget reaction gate. |

## Running and asking headlessly

Open the canvas:

```bash
./run.sh
```

Cmd/Ctrl+Enter opens the spotlight. A headless one-shot request can be issued
with:

```bash
./pharo/vm/Pharo.app/Contents/MacOS/Pharo --headless pharo/Agent.image \
  eval "AgentGateway ask: 'make me a counter widget'"
```

Real requests require `ANTHROPIC_API_KEY` and incur provider cost.

## Logs and diagnostics

Files under `logs/` are gitignored:

- `gateway.log` — append-only user requests, status events, generated code,
  tool results/errors, and complete HTTP request/response JSON;
- `provider-evaluations.jsonl` — structured evidence from explicit paid
  evaluations; provider token usage is exact, while billed USD is marked
  unavailable because the API response does not return it;
- `remote.log` — failures while starting or reviving the local listener;
- `session.status` — listener heartbeat written roughly every 30 seconds while
  the interactive watchdog is active.

In the image, `AgentGateway last log` returns the in-memory transcript of the
most recent gateway run. The API key is sent as an HTTP header and is not
intentionally logged. Canvas facts and request content do appear in full HTTP
payload logs. `gateway.log` currently has no rotation.

## Backups and recovery

Current backup behavior differs by path:

- `build.sh` backs up the previous default output `.image` and matching
  `.changes` before replacing it.
- `update.sh` backs up the `.image` before a headless update, keeping the newest
  five `pre-update-*.image` files; it does not currently copy `.changes`.
- `AgentSandbox>>backupImage` copies the last on-disk `.image` before a gateway
  request and keeps five `agent-backup-*.image` files; it does not currently
  copy `.changes` or unsaved in-memory work.

Restore only after preserving the current failed files for post-mortem. A
coherent checkpoint/recovery unit and generated-world export are tracked by
[AS-03](backlog.md#as-03--define-persistence-and-recovery-semantics).

## Remote-listener recovery

Only `AgentCanvas open` enables the loopback listener. Session startup resets
it to disabled and terminates saved AgentSmalltalk-owned processes so a
headless launch does not inherit a stale GUI listener.

If a legacy or wedged image cannot be reached by `update.sh`,
`scripts/heal-in-image.st` is the manual repair kit:

1. Open a Playground inside the running image.
2. Paste and execute the script.
3. It neutralizes stale SSL session handles, reloads platform packages, runs
   canvas migration, and snapshots the image.

The script is an emergency bootstrap, not a normal update path.

## Operational change checklist

For changes to platform source:

1. Update code and its deterministic tests.
2. Run `./test.sh`.
3. Update `system_spec.md` if observable behavior changed.
4. Update this document if commands, state, diagnostics, backup, or recovery
   behavior changed.
5. Update `security.md` if authority or data flow changed.
6. Use `update.sh` only after the relevant verification passes.
