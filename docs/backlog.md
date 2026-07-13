# Backlog

The single ordered register of actionable work for Agent Smalltalk. The order
below is an initial proposal, not a frozen roadmap. The field schema, category
vocabulary, and ordering rules are defined in the [Conventions](#conventions)
section at the end of this file; see [README.md](README.md) for the
work-item lifecycle and how the backlog relates to the other documents.

## Now

Small enough to discuss as the next foundation milestone.

| rank | ID | title | categories | priority | effort |
|---:|---|---|---|---|---|
| 1 | [AS-26](#as-26--deliver-each-async-failure-occurrence-once) | Deliver each async failure occurrence once | bug, reliability | P2 | M |
| 2 | [AS-12](#as-12--specify-whether-run-now-shifts-the-schedule) | Specify whether Run now shifts the schedule | product, bug | P2 | S |
| 3 | [AS-01](#as-01--authenticate-or-remove-the-local-evaluator) | Authenticate or remove the local evaluator | security, operations | P0 | M |
| 4 | [AS-02](#as-02--make-live-updates-verifiable-and-atomic) | Make live updates verifiable and atomic | reliability, operations | P0 | L |
| 5 | [AS-03](#as-03--define-persistence-and-recovery-semantics) | Define persistence and recovery semantics | architecture, reliability, operations | P0 | L |
| 6 | [AS-04](#as-04--treat-model-context-as-untrusted-bounded-data) | Treat model context as untrusted, bounded data | security, architecture, performance | P0 | L |
| 7 | [AS-23](#as-23--add-the-canvas-screenshot-and-clear-the-final-publication-gate) | Add the canvas screenshot and clear the final publication gate | documentation, product | P0 | S |

## Next

Important existing-system work. Its internal order should be revisited after
the `Now` decisions clarify the architecture.

| rank | ID | title | categories | priority | effort |
|---:|---|---|---|---|---|
| 8 | [AS-05](#as-05--coordinate-all-world-mutations) | Coordinate all world mutations | architecture, reliability | P1 | L |
| 9 | [AS-06](#as-06--decide-whether-automation-restrictions-are-policy-or-enforcement) | Decide whether automation restrictions are policy or enforcement | security, product, architecture | P1 | L |
| 10 | [AS-19](#as-19--make-the-base-prompt-a-tested-consistent-contract) | Make the base prompt a tested, consistent contract | testing, architecture, maintenance | P1 | M |
| 11 | [AS-27](#as-27--cache-stable-inference-context-safely) | Cache stable inference context safely | performance, architecture, security, testing | P1 | M |

## Later

Real work, but not proposed as part of the next foundation milestone.

| rank | ID | title | categories | priority | effort |
|---:|---|---|---|---|---|
| 12 | [AS-14](#as-14--introduce-a-provider-neutral-inference-boundary) | Introduce a provider-neutral inference boundary | architecture, reliability | P2 | L |
| 13 | [AS-15](#as-15--add-provenance-health-and-rollback-for-generated-artifacts) | Add provenance, health, and rollback for generated artifacts | architecture, feature, reliability | P1 | L |
| 14 | [AS-16](#as-16--make-tool-card-removal-match-its-visible-meaning) | Make tool-card removal match its visible meaning | ux, product, reliability | P2 | M |
| 15 | [AS-17](#as-17--preserve-history-when-system-messages-coalesce) | Preserve history when system messages coalesce | reliability, ux | P2 | S |
| 16 | [AS-22](#as-22--make-failed-spotlight-runs-inspectable-on-the-canvas) | Make failed Spotlight runs inspectable on the canvas | feature, ux, reliability | P1 | L |
| 17 | [AS-28](#as-28--measure-model-roi-with-provider-neutral-paid-evaluations) | Measure model ROI with provider-neutral paid evaluations | testing, performance, operations, security | P2 | L |

## Category views

These are alternate indexes over the same ordered backlog, not independent
queues. They make it possible to review one kind of work without losing the
cross-category priority order above.

| lens | items |
|---|---|
| Bugs and behavioral correctness | [AS-26](#as-26--deliver-each-async-failure-occurrence-once), [AS-12](#as-12--specify-whether-run-now-shifts-the-schedule) |
| Security and authority | [AS-01](#as-01--authenticate-or-remove-the-local-evaluator), [AS-04](#as-04--treat-model-context-as-untrusted-bounded-data), [AS-06](#as-06--decide-whether-automation-restrictions-are-policy-or-enforcement), [AS-15](#as-15--add-provenance-health-and-rollback-for-generated-artifacts), [AS-27](#as-27--cache-stable-inference-context-safely), [AS-28](#as-28--measure-model-roi-with-provider-neutral-paid-evaluations) |
| Reliability and persistence | [AS-26](#as-26--deliver-each-async-failure-occurrence-once), [AS-02](#as-02--make-live-updates-verifiable-and-atomic), [AS-03](#as-03--define-persistence-and-recovery-semantics), [AS-05](#as-05--coordinate-all-world-mutations), [AS-15](#as-15--add-provenance-health-and-rollback-for-generated-artifacts), [AS-17](#as-17--preserve-history-when-system-messages-coalesce), [AS-22](#as-22--make-failed-spotlight-runs-inspectable-on-the-canvas) |
| Operations and testing | [AS-01](#as-01--authenticate-or-remove-the-local-evaluator), [AS-02](#as-02--make-live-updates-verifiable-and-atomic), [AS-03](#as-03--define-persistence-and-recovery-semantics), [AS-19](#as-19--make-the-base-prompt-a-tested-consistent-contract), [AS-27](#as-27--cache-stable-inference-context-safely), [AS-28](#as-28--measure-model-roi-with-provider-neutral-paid-evaluations) |
| Architecture and evolution | [AS-03](#as-03--define-persistence-and-recovery-semantics), [AS-04](#as-04--treat-model-context-as-untrusted-bounded-data), [AS-05](#as-05--coordinate-all-world-mutations), [AS-06](#as-06--decide-whether-automation-restrictions-are-policy-or-enforcement), [AS-14](#as-14--introduce-a-provider-neutral-inference-boundary), [AS-15](#as-15--add-provenance-health-and-rollback-for-generated-artifacts), [AS-19](#as-19--make-the-base-prompt-a-tested-consistent-contract), [AS-27](#as-27--cache-stable-inference-context-safely) |
| Product, feature, and UX | [AS-06](#as-06--decide-whether-automation-restrictions-are-policy-or-enforcement), [AS-12](#as-12--specify-whether-run-now-shifts-the-schedule), [AS-15](#as-15--add-provenance-health-and-rollback-for-generated-artifacts), [AS-16](#as-16--make-tool-card-removal-match-its-visible-meaning), [AS-17](#as-17--preserve-history-when-system-messages-coalesce), [AS-22](#as-22--make-failed-spotlight-runs-inspectable-on-the-canvas), [AS-23](#as-23--add-the-canvas-screenshot-and-clear-the-final-publication-gate) |
| Performance and maintenance | [AS-04](#as-04--treat-model-context-as-untrusted-bounded-data), [AS-19](#as-19--make-the-base-prompt-a-tested-consistent-contract), [AS-27](#as-27--cache-stable-inference-context-safely), [AS-28](#as-28--measure-model-roi-with-provider-neutral-paid-evaluations) |

---

## Detailed entries

## AS-01 — Authenticate or remove the local evaluator

**Status:** candidate<br>
**Categories:** security, operations<br>
**Priority:** P0<br>
**Effort:** M<br>
**Dependencies:** none<br>
**Source:** repository review, 2026-07-09

### Problem and argument

`AgentRemote class>>handleRequest:` accepts unauthenticated `POST /eval` and
passes the body to `AgentSandbox`. Loopback binding limits network reach but
does not authenticate the caller: another local process receives the same
arbitrary Smalltalk authority as the agent. This is a broader trust boundary
than the README's deliberate decision to trust the agent.

### Proposed outcome

Arbitrary evaluation is disabled by default. Any remaining operator-control
channel is explicitly enabled and authenticated, with a secret that is never
logged or persisted accidentally.

### Acceptance criteria

- Unauthenticated `/eval` and `/update` requests are rejected.
- Diagnostic evaluation can be disabled completely.
- Authorized requests still work in the intended operator workflow.
- Request method, content type, and size are validated.
- Credentials never appear in logs, the canvas, or gateway context.
- Tests cover authorized, unauthorized, malformed, and disabled requests.

## AS-02 — Make live updates verifiable and atomic

**Status:** candidate<br>
**Categories:** reliability, operations<br>
**Priority:** P0<br>
**Effort:** L<br>
**Dependencies:** AS-01 for the authenticated live delivery path<br>
**Source:** repository review, 2026-07-09

### Problem and argument

The live updater mutates packages sequentially and the interactive path
snapshots inside `AgentUpdater>>migrateOnUiThreadOf:` before
`AgentRemote>>handleRequest:` verifies its sentinels. A failed verification can
therefore occur after a partial update has already been saved. Historical
selector sentinels prove that selectors exist, not that the current revision
loaded completely. The headless `update.sh` path also discards the Pharo exit
status and trusts output containing `UPDATE_OK`.

### Proposed outcome

An update is preflighted against the exact source revision, applied as one
coordinated operation, verified before snapshot, and either succeeds completely
or leaves the previous live and on-disk world intact.

### Acceptance criteria

- A disposable-image preflight loads and tests the exact candidate revision.
- Verification uses a revision/build manifest rather than old selector
  existence alone.
- The order is load, migrate, verify, then snapshot.
- `update.sh` requires both a zero process exit status and an exact success
  result.
- Injected load and migration failures leave the saved image unchanged.
- The live path either rolls back memory or declares the session tainted and
  prevents it from being saved as a valid update.

## AS-03 — Define persistence and recovery semantics

**Status:** candidate<br>
**Categories:** architecture, reliability, operations<br>
**Priority:** P0<br>
**Effort:** L<br>
**Dependencies:** AS-02<br>
**Source:** repository review, 2026-07-09

### Problem and argument

The image persists only when it is successfully snapshotted. A pre-request
backup copies the last on-disk `.image`, not unsaved current work, and does not
copy the matching `.changes` source file. Generated widgets, tools, automations,
facts, and positions have no portable export outside the mutable image. This is
weaker than the vision's current "never forgets" language and particularly
important because source browsing is part of the product.

### Proposed outcome

Users can tell whether their world is saved, create a coherent checkpoint,
restore it with browsable source intact, and export/import the generated world
independently of one image file.

### Acceptance criteria

- The product defines explicit manual or automatic checkpoint semantics.
- The UI exposes saved, unsaved, saving, and failed-save state.
- Backups atomically include `.image`, `.changes`, platform source revision,
  prompt revision, and a generated-package manifest.
- Generated packages and canvas state have an export/import path.
- A recovery test restores a checkpoint and verifies facts, tools,
  automations, widget state, positions, behavior, and browsable source.
- Vision, README, and operations language match the implemented guarantee.

## AS-04 — Treat model context as untrusted, bounded data

**Status:** candidate<br>
**Categories:** security, architecture, performance<br>
**Priority:** P0<br>
**Effort:** L<br>
**Dependencies:** none; complete before importing arbitrary external documents<br>
**Source:** repository review, 2026-07-09

### Problem and argument

Fact bodies, selected notes, tool purposes, and generated `describe` output are
concatenated directly into the system prompt without a trust boundary or total
size budget. Instruction-like imported or fetched content can therefore steer a
model that has full code-execution authority. All facts are sent even when
ordinary widget context is selection-scoped, and one large fact or a growing
toolbox can make every round increasingly expensive.

### Proposed outcome

Dynamic context is explicitly represented as untrusted data, is scoped by user
intent and privacy, and fits within a deterministic request budget.

### Acceptance criteria

- Dynamic context uses a structured representation with clear untrusted-data
  boundaries.
- The base prompt states that content inside facts, notes, descriptions, and
  fetched documents is data, never operating instruction.
- Per-object and total context limits produce visible truncation markers.
- Facts can be scoped as always-send, selected, local-only, or never-send.
- The product defines whether selection also scopes facts.
- Adversarial context tests cover instruction-like notes, facts, descriptions,
  and imported text.
- Gateway logs and UI make request-size/cost growth observable.

## AS-05 — Coordinate all world mutations

**Status:** candidate<br>
**Categories:** architecture, reliability<br>
**Priority:** P1<br>
**Effort:** L<br>
**Dependencies:** AS-02, AS-03<br>
**Source:** repository review, 2026-07-09

### Problem and argument

`AgentGateway` serializes gateway requests, but automations, live updates,
`/eval`, UI edits, reactions, and background widget refreshes can still mutate
the same living world concurrently. The current "single writer" wording is
therefore narrower than it sounds. Package reloads, class compilation,
automation execution, and snapshots can race.

### Proposed outcome

A single world coordinator defines which mutations may overlap, protects class
and package changes, and gives snapshots a stable boundary.

### Acceptance criteria

- Gateway evaluation, live updates, automation execution, diagnostic
  evaluation, and snapshots use a documented coordination protocol.
- Updates refuse or wait while incompatible work is active.
- Automation behavior during updates/checkpoints is explicit.
- UI state changes remain on the UI thread and cannot race a checkpoint.
- Tests exercise gateway/update, automation/update, and background-refresh/
  snapshot races.
- The system specification describes the actual guarantee precisely.

## AS-06 — Decide whether automation restrictions are policy or enforcement

**Status:** candidate<br>
**Categories:** security, product, architecture<br>
**Priority:** P1<br>
**Effort:** L<br>
**Dependencies:** AS-04, AS-05<br>
**Source:** repository review, 2026-07-09

### Problem and argument

The base prompt forbids destructive or irreversible unattended behavior, but an
`AgentAutomation>>run` method is unrestricted Smalltalk. Prompt guidance is not
a runtime capability boundary, especially after a human or later agent edits
the routine. Current language sometimes makes the scheduled slice sound safer
than the implementation enforces.

### Proposed outcome

Choose and consistently communicate one model:

- research mode, where automations are visibly full-authority unattended
  Smalltalk; or
- constrained mode, where declared capabilities and runtime enforcement limit
  filesystem, shell, network, gateway, messaging, and other side effects.

### Acceptance criteria

- The selected authority model is documented in the UI, prompt, security
  reference, and system specification.
- Automation cards expose their declared authority.
- If constrained mode is chosen, forbidden operations fail at runtime and are
  covered by tests.
- Any externally visible or irreversible capability has an explicit approval
  model.

## AS-12 — Specify whether Run now shifts the schedule

**Status:** candidate<br>
**Categories:** product, bug<br>
**Priority:** P2<br>
**Effort:** S<br>
**Dependencies:** none<br>
**Source:** repository review, 2026-07-09

### Problem and argument

Manual automation claims compute `nextRun` from the manual execution time. For
interval schedules, pressing **Run now** silently shifts the future cadence.
Many scheduling systems instead treat a manual run as supplemental.

### Proposed outcome

Choose and expose one understandable semantic: preserve the scheduled cadence,
or explicitly reset it from the manual run.

### Acceptance criteria

- The intended semantic is documented and visible on the card.
- Interval and daily schedules have deterministic tests for manual runs.
- The next-run label updates consistently with the chosen behavior.

## AS-14 — Introduce a provider-neutral inference boundary

**Status:** candidate<br>
**Categories:** architecture, reliability<br>
**Priority:** P2<br>
**Effort:** L<br>
**Dependencies:** AS-19<br>
**Source:** repository review, 2026-07-09

### Problem and argument

`AgentAnthropicTransport` abstracts HTTP for tests, but `AgentGateway` still
owns Anthropic payload structure and a hard-coded model. The implementation
therefore does not yet support the vision's provider-neutral wording.

### Proposed outcome

The core loop speaks a provider-neutral turn/tool protocol. Provider adapters
translate that protocol to Anthropic, OpenAI, or another service.

### Acceptance criteria

- Provider, model, token limit, and timeouts are externally configurable.
- Provider adapters own request/response translation and validation.
- HTTP clients close resources reliably.
- Retry/backoff is limited to safe, retryable provider failures and cannot
  duplicate local tool mutations.
- Fake adapters exercise malformed responses, rate limits, timeouts, and final
  text/tool sequences.

## AS-15 — Add provenance, health, and rollback for generated artifacts

**Status:** candidate<br>
**Categories:** architecture, feature, reliability<br>
**Priority:** P1<br>
**Effort:** L<br>
**Dependencies:** AS-03, AS-05<br>
**Source:** repository review, 2026-07-09

### Problem and argument

A failed, timed-out, or cancelled agent run can leave classes, methods,
instances, cards, tools, processes, or subscriptions behind. Generated source
has no run provenance, health state, portable history, or run-level undo. As
the toolbox grows, invisible technical debt will undermine the promise that the
environment improves through use.

### Proposed outcome

Every generated artifact records where it came from, whether it was verified,
what depends on it, and how to export, supersede, or roll it back.

### Acceptance criteria

- Agent runs have stable IDs attached to created/modified artifacts.
- Provenance includes time, request, provider/model, prompt revision, and
  verification result without storing secrets.
- Artifacts expose draft, verified, failing, and superseded health states.
- Failed attempts can be inspected and cleaned up deliberately.
- Generated packages export to Tonel and participate in AS-03 recovery.
- A run-level change summary and rollback design are tested on representative
  class, method, and canvas changes.

## AS-16 — Make tool-card removal match its visible meaning

**Status:** candidate<br>
**Categories:** ux, product, reliability<br>
**Priority:** P2<br>
**Effort:** M<br>
**Dependencies:** AS-15<br>
**Source:** completed self-built-tools work and repository review

### Problem and argument

A tool card has the same visible `x` as cards that are actually deleted, but
removing it leaves the executable tool discoverable in every future prompt.
Automation-card deletion really unregisters its routine. Identical controls
therefore have materially different authority semantics.

### Proposed outcome

Hiding a tool's visual card and forgetting its executable capability are
separate, explicit operations with clear dependency consequences.

### Acceptance criteria

- A hide/dismiss control does not look like destructive deletion.
- **Forget tool** checks and displays dependents before removing source.
- Tool cards expose health, dependents, last verification, and provenance.
- Deleting, hiding, forgetting, undoing, and restoring have tests and consistent
  wording.

## AS-17 — Preserve history when system messages coalesce

**Status:** candidate<br>
**Categories:** reliability, ux<br>
**Priority:** P2<br>
**Effort:** S<br>
**Dependencies:** none<br>
**Source:** repository review, 2026-07-09

### Problem and argument

Keyed system messages replace the previous body and increment a counter. When
successive failures differ, useful earlier diagnostics disappear even though
the card suggests repeated occurrences.

### Proposed outcome

Coalescing controls visual noise without discarding the bounded diagnostic
history required to understand repeated failures.

### Acceptance criteria

- A keyed message retains a bounded occurrence history or at least first,
  latest, timestamps, and count.
- The card summarizes repetitions and offers a way to inspect details.
- Gateway async-failure reporting does not miss a newly recreated occurrence.
- Tests cover identical and differing repeated messages.

## AS-19 — Make the base prompt a tested, consistent contract

**Status:** candidate<br>
**Categories:** testing, architecture, maintenance<br>
**Priority:** P1<br>
**Effort:** M<br>
**Dependencies:** AS-04<br>
**Source:** repository review, 2026-07-09

### Problem and argument

The base prompt is a large load-bearing program, but most prompt tests assert
only that phrases are present. It says `evaluate_smalltalk` is the only action
tool despite also teaching `search_image`, and its tool example visually places
class definition and class use in one code block despite requiring separate
calls. The reactive retrofit recipe can also touch off-canvas instances and
lose live state.

### Proposed outcome

The prompt has one consistent operational contract, smaller reusable sections,
and behavioral evaluations for common workflows and failure cases.

### Acceptance criteria

- Inspection and mutation tools are described without contradiction.
- Every multi-call example labels its call boundaries explicitly.
- Live-instance modification recipes preserve state, position, subscriptions,
  and undo semantics.
- Reactive headless construction cannot leave ghost subscribers.
- Tests validate model/tool behavior through scripted scenarios rather than
  phrase presence alone.
- Reusable, tested tools replace prompt recipes only when evidence shows the
  replacement is more reliable.

## AS-22 — Make failed Spotlight runs inspectable on the canvas

**Status:** ready<br>
**Categories:** feature, ux, reliability<br>
**Priority:** P1<br>
**Effort:** L<br>
**Dependencies:** AS-04; coordinate stable run identity and provenance with AS-15<br>
**Source:** shared human/agent debugging brainstorm, 2026-07-11

### Problem and argument

When a Spotlight request fails, the evidence needed to understand it lives
primarily in external gateway logs and request/response payloads. The user sees
a generic failure while the agent cannot inspect the failed loop unless the
user manually retrieves and supplies diagnostics. Projecting every successful
run, performance statistic, or log event onto the canvas would instead create
noise and mix failure diagnosis with a separate observability/optimization
problem.

### Proposed outcome

Every definite Spotlight/gateway failure creates one bounded, redacted,
inspectable canvas card near the failed interaction. The card lets a human
inspect the trace without invoking the agent and explicitly invite the agent to
debug the same visible evidence. Successful runs remain silent. This canvas
projection complements rather than replaces independent external logs, traces,
metrics, and debuggers.

### Acceptance criteria

- Each Spotlight submission keeps a bounded diagnostic buffer while it runs;
  a successful terminal outcome creates no diagnostic canvas object.
- An unresolved exception, gateway/model/tool error, invalid response,
  rejected application, timeout, exhausted model loop, or explicit
  unable-to-complete outcome creates exactly one failure card. An intermediate
  error repaired before a successful terminal outcome does not.
- The final run outcome determines failure even if text or a widget was created
  before a later failure. A valid but disappointing or misunderstood result is
  outside this first slice and creates no automatic card.
- The card is an ordinary, persistent canvas object placed in the current
  viewport near the failed interaction. It opens to a concise summary without
  becoming modal, taking keyboard focus, or blocking continued canvas work.
- A bounded, scrollable detail view orders the submitted prompt and effective
  context, model responses, tool calls/results, repair attempts, terminal
  failure, and objects created or modified before failure.
- Credentials, API keys, authorization headers, cookies, and recognized
  secrets are excluded before diagnostics are persisted, rendered, or sent.
  Large request, response, and tool-result bodies are truncated with visible
  markers and deterministic limits.
- **Inspect trace** reveals the stored evidence without invoking the model.
  **Debug this run** opens Spotlight and explicitly includes only the same
  visible, redacted, bounded capsule. Selecting or ignoring the card never
  silently adds it to an unrelated prompt.
- Failure cards survive image saves and reopening like normal canvas objects
  and remain until the user deletes them; there is no pinned/unpinned state or
  automatic cleanup in this slice.
- External diagnostics remain independently available if the image, UI, or
  canvas projection fails. Shared collection code must not make the canvas a
  required logging sink or materially alter run timing and failure behavior.
- Automated tests cover successful, repaired, partial-change, malformed,
  timeout, and unable-to-complete runs; redaction and size limits; card
  placement/focus; persistence; and both inspection actions.

### Explicitly deferred

- Token cost, performance analysis, latency dashboards, and general successful
  run inspection, except timing directly required to explain a failure.
- User-reported semantic failures where the run completed validly but did not
  satisfy the user's intent.
- Post-creation widget/runtime failures from reactions, scheduled automations,
  background refreshes, and widget interactions. A later slice can reuse the
  diagnostic event model with widget/trigger attribution and repeated-failure
  coalescing.

## AS-23 — Add the canvas screenshot and clear the final publication gate

**Status:** ready<br>
**Categories:** documentation, product<br>
**Priority:** P0<br>
**Effort:** S<br>
**Dependencies:** AS-02, AS-03 (do not publish before the persistence/update model is clear)<br>
**Source:** AS-20 follow-up, 2026-07-13

### Problem and argument

The open-source readiness pass (former AS-20) landed the license, the
contribution guide, a shared writing-voice guide, the architecture overview, and
platform/disk-time expectations. Two gaps remain before a first public release:
the README still promises a canvas screenshot it does not have, and the
repository has not had a single end-to-end pass to confirm nothing else blocks a
newcomer with no private context.

### Proposed outcome

The README shows a representative canvas, and a short pre-publication sweep
confirms the repository is ready to open to newcomers.

### Acceptance criteria

- A representative canvas is agreed, captured, stored under `docs/assets/`, and
  embedded in the README `Demo` section, replacing the `TODO(AS-23)` placeholder.
- The screenshot reflects the current UI (post canvas redesign) and shows the
  core object kinds — a fact, a widget, and a tool card or routine.
- A final readiness sweep confirms links resolve, commands match the current
  scripts, the contributor PR flow and issue triage are documented, and no
  private-context assumptions remain.
- Publication still respects the AS-02/AS-03 persistence/update gate.

## AS-26 — Deliver each async failure occurrence once

**Status:** ready<br>
**Categories:** bug, reliability<br>
**Priority:** P2<br>
**Effort:** M<br>
**Dependencies:** none; coordinate occurrence identity and history with AS-17<br>
**Source:** repository code review and disposable-image reproduction, 2026-07-13

### Problem and argument

`AgentGateway>>pendingAsyncFailures` records delivered message counts in the
gateway instance. Spotlight creates a new gateway for every submission, so a
persistent `widgetUpdateFailure-*` system message appears undelivered to every
new request. The same old occurrence is injected into the first tool result
again and again until the user deletes its card, steering unrelated requests
back toward a stale failure.

### Proposed outcome

Async widget failures have durable occurrence identity and delivery state.
Each occurrence reaches the next available gateway tool result once, including
when it happens after a request's final tool call, without contaminating later
requests after delivery.

### Acceptance criteria

- One failure occurrence is surfaced once across two consecutive gateway
  instances, not once per instance.
- A later coalesced occurrence of the same keyed failure is surfaced once
  again.
- A failure that occurs after the final tool result is delivered by the next
  request without being lost or repeated afterward.
- Deleting and later recreating a keyed failure produces a new occurrence that
  is not hidden by an older delivered count.
- Tests cover same-gateway, cross-gateway, coalesced, and delete/recreate paths.

## AS-27 — Cache stable inference context safely

**Status:** candidate<br>
**Categories:** performance, architecture, security, testing<br>
**Priority:** P1<br>
**Effort:** M<br>
**Dependencies:** AS-04, AS-19; coordinate adapter-specific cache semantics with AS-14<br>
**Source:** model ROI discussion and repository measurement, 2026-07-13

### Problem and argument

The 27,396-character base prompt, tool definitions, dynamic canvas context, and
growing turn history are sent again on every model round. The gateway records
provider cache-creation and cache-read token fields but does not identify a
stable cacheable prefix or request caching from the provider. Long repair loops
therefore pay repeatedly for mostly identical input and carry avoidable latency.
Caching without an explicit boundary would create a different risk: user or
canvas data could be retained or reused beyond the request that authorized it.

### Proposed outcome

The inference request separates versioned, stable instructions from dynamic
user and canvas data. Provider adapters cache the stable prefix when their API
supports it, fall back to an ordinary uncached request when it does not, and
expose enough evidence to verify hits, invalidation, cost, and unchanged model
behavior.

### Acceptance criteria

- The cacheable prefix contains only reviewed platform instructions and stable
  tool schemas; user text, canvas objects, tool results, and generated code are
  dynamic and are not reused across independent runs.
- Cache identity accounts for serving provider, pinned model, base-prompt
  revision, tool-schema revision, and generation settings that affect cache
  validity.
- A prompt or tool-schema change invalidates the old prefix deterministically;
  an unchanged follow-up round can produce a cache hit.
- Adapters own provider-specific cache controls and usage translation. A model
  or provider without safe cache support continues uncached without changing
  gateway semantics.
- Evaluation evidence distinguishes uncached input, cache writes, cache reads,
  output, and provider-reported reasoning tokens where applicable.
- Deterministic tests cover prefix composition, exclusion of dynamic data,
  invalidation, unsupported providers, malformed cache usage, and uncached
  fallback.
- An explicit paid evaluation records cold and warm runs against the same
  prompt revision and reports token cost, latency, rounds, repairs, and semantic
  outcome. It is never part of `verify-all.sh`.
- The system specification, operations guide, and security model document the
  implemented cache boundary, observability, provider retention assumptions,
  and invalidation behavior.

## AS-28 — Measure model ROI with provider-neutral paid evaluations

**Status:** candidate<br>
**Categories:** testing, performance, operations, security<br>
**Priority:** P2<br>
**Effort:** L<br>
**Dependencies:** AS-14, AS-19, AS-27<br>
**Source:** model ROI discussion, 2026-07-13

### Problem and argument

The paid smoke scripts exercise useful behavior, but the gateway and runner are
tied to one provider and model, each scenario normally runs once, and recorded
usage is not converted into dated cost. Public coding benchmarks do not test
Pharo/Bloc generation, live compilation, state preservation, or repair through
this project's tool loop. Nominal token prices also hide tokenizer differences,
reasoning-token billing, cache behavior, failed runs, and additional rounds.
A cheap model that needs repeated repairs can cost more per successful request.

### Proposed outcome

An explicit, budgeted bake-off runs pinned candidates through the same semantic
scenarios in fresh disposable images. It ranks models by cost per successful
evaluation while reporting pass rate, latency, repairs, and operational limits
separately. Candidate selection also records where inference runs and which
company serves it, rather than treating a model name as the whole trust
boundary.

### Acceptance criteria

- A versioned candidate manifest records model publisher, pinned model ID,
  serving provider, API and endpoint region, reasoning settings, context and
  output limits, data-retention/training terms with dated source links, and
  prices with their retrieval date.
- Models published by organizations outside the United States are evaluated
  only through a US-based serving provider, not the publisher's own non-US
  service. A US processing region is selected when the serving provider offers
  regional control, and the actual region or lack of a guarantee is reported.
- The current production model is the baseline. Screening includes at least
  three challengers from at least two model families, subject to the serving
  policy above.
- Candidates first pass request/response and tool-call contract tests. The paid
  stage uses a declared budget and sample count; finalists run the full semantic
  suite at least five times per scenario and prompt revision.
- Every run uses the same base-prompt and tool-schema revisions, fresh image
  setup, round cap, output limit, and declared reasoning policy. Cached and
  uncached results are separated rather than silently mixed.
- Evidence records semantic outcome, input/cache/reasoning/output usage,
  calculated USD cost, latency, rounds, repair attempts, malformed tool calls,
  and asynchronous failures that appear after an apparent success.
- The primary comparison is cost per semantic pass. Pass rate, p50/p95 latency,
  repair distribution, and sample count remain visible so one cheap outlier
  cannot become the recommendation.
- A failed candidate cannot hand the partially mutated image to another model;
  every retry or fallback begins from the scenario's fresh state.
- Results are written as machine-readable evidence plus a dated summary that
  names the winning conditions and limitations. Price or model changes make
  the summary stale without rewriting the historical evidence.
- Paid comparisons remain an explicit operator action and never run from
  `verify-all.sh` or routine builds.

---

## Conventions

### Fields

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

### Ordering

The `Now`, `Next`, and `Later` tables at the top of this file are the planning
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
