# Backlog

The ordered register of actionable work for Agent Smalltalk. The table below is
the current top-ten planning view; the detailed entries retain lower-priority
work so it is not lost. The order is an initial proposal, not a frozen roadmap.
The field schema, category vocabulary, and ordering rules are defined in the
[Conventions](#conventions) section at the end of this file; see
[README.md](README.md) for the work-item lifecycle and how the backlog relates
to the other documents.

## Top 10 priorities

These are the ten items we should address first, in agreed order. Detailed
entries below the category views include additional backlog candidates that are
not currently in the top ten.

| rank | ID | title | categories | priority | effort |
|---:|---|---|---|---|---|
| 1 | [AS-27](#as-27--cache-stable-inference-context-safely) | Cache stable inference context safely | performance, architecture, security, testing | P1 | M |
| 2 | [AS-14](#as-14--introduce-a-provider-neutral-inference-boundary) | Introduce a provider-neutral inference boundary | architecture, reliability | P2 | L |
| 3 | [AS-17](#as-17--preserve-history-when-system-messages-coalesce) | Preserve history when system messages coalesce | reliability, ux | P2 | S |
| 4 | [AS-22](#as-22--make-failed-spotlight-runs-inspectable-on-the-canvas) | Make failed Spotlight runs inspectable on the canvas | feature, ux, reliability | P1 | L |
| 5 | [AS-28](#as-28--measure-model-roi-with-provider-neutral-paid-evaluations) | Measure model ROI with provider-neutral paid evaluations | testing, performance, operations, security | P2 | L |
| 6 | [AS-03](#as-03--define-persistence-and-recovery-semantics) | Define persistence and recovery semantics | architecture, reliability, operations | P0 | L |
| 7 | [AS-29](#as-29--clear-the-final-publication-gate) | Clear the final publication gate | documentation, operations, product | P0 | S |
| 8 | [AS-05](#as-05--coordinate-all-world-mutations) | Coordinate all world mutations | architecture, reliability | P1 | L |
| 9 | [AS-06](#as-06--decide-whether-automation-restrictions-are-policy-or-enforcement) | Decide whether automation restrictions are policy or enforcement | security, product, architecture | P1 | L |
| 10 | [AS-15](#as-15--add-provenance-health-and-rollback-for-generated-artifacts) | Add provenance, health, and rollback for generated artifacts | architecture, feature, reliability | P1 | L |

## Category views

These are alternate indexes over the full detailed backlog, not independent
queues. The top-ten table is the ranked planning surface; these views also
include unranked candidates outside it.

| lens | items |
|---|---|
| Bugs and behavioral correctness | *(none currently)* |
| Security and authority | [AS-01](#as-01--authenticate-or-remove-the-local-evaluator), [AS-06](#as-06--decide-whether-automation-restrictions-are-policy-or-enforcement), [AS-15](#as-15--add-provenance-health-and-rollback-for-generated-artifacts), [AS-27](#as-27--cache-stable-inference-context-safely), [AS-28](#as-28--measure-model-roi-with-provider-neutral-paid-evaluations) |
| Reliability and persistence | [AS-03](#as-03--define-persistence-and-recovery-semantics), [AS-05](#as-05--coordinate-all-world-mutations), [AS-15](#as-15--add-provenance-health-and-rollback-for-generated-artifacts), [AS-17](#as-17--preserve-history-when-system-messages-coalesce), [AS-22](#as-22--make-failed-spotlight-runs-inspectable-on-the-canvas) |
| Operations and testing | [AS-01](#as-01--authenticate-or-remove-the-local-evaluator), [AS-03](#as-03--define-persistence-and-recovery-semantics), [AS-27](#as-27--cache-stable-inference-context-safely), [AS-28](#as-28--measure-model-roi-with-provider-neutral-paid-evaluations), [AS-29](#as-29--clear-the-final-publication-gate), [AS-30](#as-30--decide-when-to-move-to-pharo-14) |
| Architecture and evolution | [AS-03](#as-03--define-persistence-and-recovery-semantics), [AS-05](#as-05--coordinate-all-world-mutations), [AS-06](#as-06--decide-whether-automation-restrictions-are-policy-or-enforcement), [AS-14](#as-14--introduce-a-provider-neutral-inference-boundary), [AS-15](#as-15--add-provenance-health-and-rollback-for-generated-artifacts), [AS-27](#as-27--cache-stable-inference-context-safely), [AS-30](#as-30--decide-when-to-move-to-pharo-14) |
| Product, feature, and UX | [AS-06](#as-06--decide-whether-automation-restrictions-are-policy-or-enforcement), [AS-15](#as-15--add-provenance-health-and-rollback-for-generated-artifacts), [AS-16](#as-16--make-tool-card-removal-match-its-visible-meaning), [AS-17](#as-17--preserve-history-when-system-messages-coalesce), [AS-22](#as-22--make-failed-spotlight-runs-inspectable-on-the-canvas), [AS-29](#as-29--clear-the-final-publication-gate), [AS-31](#as-31--tell-a-first-time-image-how-to-start) |
| Performance and maintenance | [AS-27](#as-27--cache-stable-inference-context-safely), [AS-28](#as-28--measure-model-roi-with-provider-neutral-paid-evaluations), [AS-30](#as-30--decide-when-to-move-to-pharo-14) |

---

## Detailed entries

## AS-01 — Authenticate or remove the local evaluator

**Status:** postponed<br>
**Categories:** security, operations<br>
**Priority:** P2<br>
**Effort:** M<br>
**Dependencies:** none; revisit before publication (AS-29)<br>
**Source:** repository review, 2026-07-09; postponed 2026-07-15

### Problem and argument

`AgentRemote class>>handleRequest:` hands any local caller the authority the
README grants only to the agent; the [security model](security.md) states that
boundary and why it is accepted for now. This item holds the work that closing
it would take, so a later reviewer finds a decision here instead of filing the
finding again: authenticating `/update`, which `update.sh` depends on, and
authenticating or dropping `/eval`, which is what the operator and any code
agent use to question a live session. That price is worth paying to publish and
not worth paying to experiment, so the trigger is publication, not the calendar.

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

## AS-03 — Define persistence and recovery semantics

**Status:** postponed<br>
**Categories:** architecture, reliability, operations<br>
**Priority:** P0<br>
**Effort:** L<br>
**Dependencies:** none<br>
**Source:** repository review, 2026-07-09; design review and postponed 2026-07-15

### Problem and argument

The image persists only when it is successfully snapshotted. A pre-request
backup copies the last on-disk `.image`, not unsaved current work, and does not
copy the matching `.changes` source file. Generated widgets, tools, automations,
facts, and positions have no portable export outside the mutable image. This is
weaker than the vision's current "never forgets" language and particularly
important because source browsing is part of the product. The agent can also
reshape generated classes, patch existing methods, and mutate live object
instances, so a portable boundary cannot be inferred from package names alone.

### Decision

Postpone implementation at the current research-prototype stage. Routine
platform updates already preserve the living world in place, while coherent
checkpoints and cross-image migration would add a compatibility and security
surface before a concrete user need has tested it. The accepted limits,
candidate architecture, and return triggers are recorded in the
[deferred design](postponed.md#as-03--persistence-recovery-and-portable-world-migration).

### Proposed outcome

Users can tell whether their world is saved, create a coherent checkpoint,
restore it with browsable source intact, and export/import the generated world
independently of one image file.

### Acceptance criteria

- The product defines explicit manual or automatic checkpoint semantics.
- The UI exposes saved, unsaved, saving, and failed-save state.
- Checkpoints atomically include `.image`, `.changes`, compatible runtime
  identification, platform and prompt revisions, a generated-package manifest,
  checksums, and an unambiguous completion marker.
- Generated packages export as Tonel; logical world state uses a versioned data
  format with stable object identities and explicit migration steps.
- Platform or dependency patches carry a baseline revision and pre-change hash;
  an import reports conflicts instead of applying a stale patch silently.
- Imports validate data and code in a staged image, restore automations disabled,
  and promote the result only after verification.
- A recovery test restores a checkpoint and verifies facts, tools,
  automations, widget state, positions, behavior, and browsable source.
- Vision, README, and operations language match the implemented guarantee.

## AS-05 — Coordinate all world mutations

**Status:** candidate<br>
**Categories:** architecture, reliability<br>
**Priority:** P1<br>
**Effort:** L<br>
**Dependencies:** AS-03<br>
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
**Dependencies:** AS-05<br>
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

## AS-14 — Introduce a provider-neutral inference boundary

**Status:** candidate<br>
**Categories:** architecture, reliability<br>
**Priority:** P2<br>
**Effort:** L<br>
**Dependencies:** none<br>
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

## AS-22 — Make failed Spotlight runs inspectable on the canvas

**Status:** ready<br>
**Categories:** feature, ux, reliability<br>
**Priority:** P1<br>
**Effort:** L<br>
**Dependencies:** AS-15, for stable run identity and provenance<br>
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

## AS-27 — Cache stable inference context safely

**Status:** candidate<br>
**Categories:** performance, architecture, security, testing<br>
**Priority:** P1<br>
**Effort:** M<br>
**Dependencies:** coordinate adapter-specific cache semantics with AS-14<br>
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
**Dependencies:** AS-14, AS-27<br>
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

## AS-29 — Clear the final publication gate

**Status:** blocked<br>
**Categories:** documentation, operations, product<br>
**Priority:** P0<br>
**Effort:** S<br>
**Dependencies:** AS-03 (postponed; do not publish before the persistence model is clear)<br>
**Source:** AS-23 split, 2026-07-15

### Problem and argument

The open-source readiness pass (former AS-20) landed the license, the
contribution guide, the writing-voice guide, the architecture overview, and
platform/disk-time expectations. Its follow-up (former AS-23) added the canvas
screenshot the README had been promising. What remains is the part that was
never really a documentation task: the repository has not had a single
end-to-end pass by someone assuming no private context, and publishing is still
gated on the persistence and update model being clear. Those two are held
together here so the last P0 before a public release says plainly what it is
waiting for.

### Proposed outcome

A short sweep confirms the repository is ready to open to newcomers, and
publication happens only once the persistence/update model behind it is settled.

### Acceptance criteria

- A readiness sweep confirms links resolve, commands match the current scripts,
  the contributor PR flow and issue triage are documented, and no
  private-context assumptions remain.
- Publication respects the AS-03 persistence gate: the item cannot close while
  it is open.

## AS-30 — Decide when to move to Pharo 14

**Status:** candidate<br>
**Categories:** maintenance, operations, architecture<br>
**Priority:** P2<br>
**Effort:** M<br>
**Dependencies:** none; the upgrade itself interacts with AS-03, since a living
world is the thing being carried across<br>
**Source:** platform currency review, 2026-07-15

### Problem and argument

The project is pinned to Pharo 13 in more places than a version string: the
README and [operations guide](operations.md) document a Pharo 13 image and the
`stable` VM, `build.sh` expects a Pharo 13 pristine image, the base prompt tells
the model what image it lives in, and the system specification names the
platform. Staying on an aging release is a slow tax — Bloc, Alexandrie, and the
Pharo tooling all move on, and the longer the gap grows the less the upgrade
looks like a version bump and the more it looks like a port.

The counterweight is that this project's whole value lives inside a mutable
image. A new major Pharo release is not automatically a good home for it, and
finding out the hard way is expensive. So the first half of this item is not an
upgrade at all; it is a decision with evidence behind it.

### Proposed outcome

A dated readiness assessment says whether Pharo 14 is a viable host for this
project, and — if it is — a concrete upgrade plan exists with the conditions
that would trigger it. If it is not viable yet, the assessment records the
specific blockers so the next look is cheap.

### Acceptance criteria

- The assessment records Pharo 14's release status, whether an arm64 macOS image
  and VM are published, and how its stability is being characterized upstream.
- Every dependency the project actually relies on — Bloc, Alexandrie, Toplo,
  Zinc, NeoJSON, and the test tooling — is checked for a Pharo 14 story, and the
  gaps are named rather than assumed.
- A throwaway Pharo 14 image attempts a full load of the project's packages and
  a deterministic verification run; the result is reported honestly, including
  partial failure.
- The assessment names what an upgrade would cost across the pinned surfaces:
  README, operations guide, `build.sh`, `run.sh`, `update.sh`, the base prompt,
  and the system specification.
- If Pharo 14 is viable, an upgrade plan exists with a migration path for
  existing images, a rollback story, and an explicit trigger (a Pharo release
  milestone, a dependency dropping Pharo 13 support, or a feature the project
  actually wants).
- If it is not viable, the blockers and a revisit trigger are recorded, and this
  item stays open rather than closing as "not now".

## AS-31 — Tell a first-time image how to start

**Status:** candidate<br>
**Categories:** ux, product, documentation<br>
**Priority:** P2<br>
**Effort:** S<br>
**Dependencies:** none<br>
**Source:** onboarding observation, 2026-07-15

### Problem and argument

A fresh image opens on an empty canvas that says nothing about itself. The one
gesture that unlocks everything — Cmd/Ctrl+Enter to summon the Spotlight — is
documented in the README and the operations guide, which is exactly where a
person who has just double-clicked the image is not looking. Right-click to
browse, the resize grip, and lasso selection are in the same position: real
affordances with no visible hint. The canvas is discoverable only to someone who
already read about it, which is a strange property for a product whose whole
pitch is that you talk to it.

The counter-argument is that permanent chrome would fight the empty-canvas
aesthetic and become noise the second time you open the image. So the useful
version of this is a first-run affordance that knows it is a first run, and that
gets out of the way for good once the user has actually done the thing.

### Proposed outcome

A first-time image shows the user how to start without teaching a tutorial. The
hint states the summoning shortcut, is dismissible, disappears once the user has
opened the Spotlight, and never returns in a world that has been used.

### Acceptance criteria

- A fresh image displays the Spotlight shortcut on the empty canvas; the hint is
  visible without a click and readable without documentation.
- The hint is dismissible, and opening the Spotlight dismisses it implicitly. A
  world that has been used never shows it again, across image saves.
- The hint is a canvas-native affordance, not a modal: it does not take keyboard
  focus, block canvas work, or interfere with lasso selection or placement.
- Beyond the shortcut, the hint suggests at most one concrete first request, so
  the empty canvas has an obvious next move rather than a feature list.
- Whether the other unlabeled gestures — right-click to browse, resize grip,
  Cmd/Ctrl+Z — belong in this surface is decided explicitly and recorded, rather
  than accumulating by default.
- The README and system specification describe the first-run behavior, and tests
  cover a fresh world, a dismissed hint, and a used world after reopening.

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

The `Top 10 priorities` table at the top of this file is the planning surface.
Reordering those rows should be a small, explicit change; detailed entries do
not need to move or be rewritten. Items outside the top ten remain available
for promotion when the order changes, but do not receive a planning rank until
they enter the table.

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
deterministic verification path, checks this invariant along with the ten
contiguous ranks and agreement between planning rows and detailed entries.
