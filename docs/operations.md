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

`build.sh`, `test.sh`, and `update.sh` accept `PHARO_VM`; `build.sh` and the
preflight inside `update.sh` also accept `PHARO_PRISTINE`. `run.sh` still uses
the macOS bundle path directly.

## Command summary

| command | purpose | effect on living world |
|---|---|---|
| `./build.sh` | Build a fresh full image from pristine Pharo and `src/`; run tests before replacement by default. | Replaces the target world after success. Existing default target is backed up first. |
| `./build.sh core` | Build gateway/sandbox/core tests without Bloc UI. | Creates/replaces the requested target image. |
| `./build.sh --output /tmp/Review.image` | Build a disposable full image at another path. | Does not replace `pharo/Agent.image`. |
| `./update.sh` | Preflight and reload platform packages into the living image. | Preserves generated classes and canvas state; promotes a staged image only after verification. |
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

Before either path, `update.sh` copies `src/` into a private candidate, hashes
that source tree, writes the resulting revision/build manifest into the
candidate, and runs the full disposable-image SUnit suite against it. The
preflight image must load the same manifest marker. This is the candidate the
delivery path receives; later edits to the working tree cannot change it.

`AgentUpdater` reloads the five platform packages with Tonel diff semantics,
runs canvas migrations (on the UI thread when necessary), verifies the loaded
candidate manifest, and only then posts the update message and snapshots.

For a closed image, the loader runs against staged `.image` and `.changes`
copies in `pharo/`. `update.sh` requires both a zero Pharo exit status and one
exact `UPDATE_OK <manifest>` line before it backs up and promotes the staged
pair. A load, migration, verification, or process failure leaves the original
pair unchanged.

For a live image, the listener accepts the private candidate path and manifest,
then follows the same load → migrate → verify → snapshot order. If any step
after loading begins fails, it marks the in-memory session **tainted**, returns
`UPDATE_TAINTED`, and does not snapshot it. Quit that session without saving;
the prior on-disk world remains the recovery point.

The live protocol identifies itself as `update-v1` on `GET /ping`. `update.sh`
will not send a staged candidate to an older listener. Quit that image without
saving and run `./update.sh` headlessly to make the one-time transition.
Local listener authentication remains the accepted [AS-01](backlog.md#as-01--authenticate-or-remove-the-local-evaluator)
risk.

## Testing

`./test.sh` creates a disposable image, loads the pinned production dependency
graph and all project packages, then runs the suite enumerated in
`scripts/run-tests.st`.

The suite is strongest for deterministic object behavior: gateway tool
plumbing with a fake transport, sandbox results and timeouts, fact/note/context
behavior, selection math, scheduler timing, histories, widget lifecycle, and
tool cards. It does not make paid provider calls or prove the living image's
full snapshot/recovery path.

`scripts/test-update-atomicity.sh` is the focused update-path integration
check. It copies `pharo/Agent.image` and `.changes` to `/tmp`, injects load and
migration failures into the staged headless path, and compares both saved files
after each failure. It is deliberately outside `verify-all.sh`: each case runs
the full disposable preflight and needs a local living image to copy.

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
| `smoke-fact-retrieval.st` | yes | Tool-first exact reference and bounded broad fact-discovery gate. |
| `smoke-fact-baseline.st` | yes | Compares tool-first retrieval with a disposable always-serialized-facts baseline; records answer quality and exact token/payload deltas without assuming either must be lower. |
| `smoke-context-adversarial.st` | yes | Selected fact, note/import-style text, and widget-description injection gate; records one model/prompt outcome, not a security proof. |
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
  tool results/errors, complete HTTP request/response JSON, and one
  `agent-request-metrics/v1` JSON record per provider response. The record
  includes latest/cumulative serialized payload characters, dynamic-context
  and knowledge-result budgets, exact provider token usage, and an explicit
  billed-USD-unavailable marker;
- `provider-evaluations.jsonl` — structured evidence from explicit paid
  evaluations; provider token usage is exact, while billed USD is marked
  unavailable because the API response does not return it;
- `remote.log` — failures while starting or reviving the local listener;
- `session.status` — listener heartbeat written roughly every 30 seconds while
  the interactive watchdog is active.

In the image, `AgentGateway last log` returns the in-memory transcript and
`AgentGateway last requestMetrics` returns the latest structured growth summary.
The spotlight closes after a successful request; the provider does not return
billed USD, so metrics record it as unavailable rather than estimating a price.
The API key is sent as an HTTP header and is not
intentionally logged. Canvas facts and request content do appear in full HTTP
payload logs. `gateway.log` currently has no rotation.

### Questioning a live session

Those files are a record of what happened. To ask the running image what is true
*now* — live selections, widget state, an automation's runtime state — post the
expression to the loopback evaluator:

```bash
curl -s -X POST --data-binary 'AgentAutomation allInstances size' \
  http://127.0.0.1:8807/eval
```

A headless `Pharo eval` cannot answer these questions: it loads the image file,
not the session in front of you, so anything held only in the live world is
invisible to it. The remaining alternative is pasting into a Playground, which
needs a human at the keyboard and so is closed to a code agent working alone.

`AgentSandbox` evaluates the body, so the reply is the same `RESULT:`/`ERROR:`
report the model gets, and the same rotating image backups make a bad expression
recoverable. It is an instrument for a deliberate investigation: it carries full
image authority and authenticates nobody, which
[the security model](security.md#known-risks-and-planned-work) accepts on
purpose and explains.

## Backups and recovery

Current backup behavior differs by path:

- `build.sh` backs up the previous default output `.image` and matching
  `.changes` before replacing it.
- `update.sh` backs up the `.image` and matching `.changes` before promoting a
  verified staged headless update, keeping the newest five `pre-update-*`
  pairs. Live updates snapshot in place after verification; their prior
  on-disk pair is already the recovery point if the session becomes tainted.
- `AgentSandbox>>backupImage` copies the last on-disk `.image` before a gateway
  request and keeps five `agent-backup-*.image` files; it does not currently
  copy `.changes` or unsaved in-memory work.

Restore only after preserving the current failed files for post-mortem. A
coherent checkpoint/recovery unit and generated-world export are deliberately
deferred. [AS-03](backlog.md#as-03--define-persistence-and-recovery-semantics)
records the accepted limit and links the design and return triggers.

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
