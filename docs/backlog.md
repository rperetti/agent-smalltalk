# Backlog

The single ordered register of actionable work for Agent Smalltalk. The order
below is an initial proposal, not a frozen roadmap. See [README.md](README.md)
for field definitions, categories, and the work-item lifecycle.

## Now

Small enough to discuss as the next foundation milestone.

| rank | ID | title | categories | priority | effort |
|---:|---|---|---|---|---|
| 1 | [AS-01](#as-01--authenticate-or-remove-the-local-evaluator) | Authenticate or remove the local evaluator | security, operations | P0 | M |
| 2 | [AS-02](#as-02--make-live-updates-verifiable-and-atomic) | Make live updates verifiable and atomic | reliability, operations | P0 | L |
| 3 | [AS-03](#as-03--define-persistence-and-recovery-semantics) | Define persistence and recovery semantics | architecture, reliability, operations | P0 | L |
| 4 | [AS-04](#as-04--treat-model-context-as-untrusted-bounded-data) | Treat model context as untrusted, bounded data | security, architecture, performance | P0 | L |

## Next

Important existing-system work. Its internal order should be revisited after
the `Now` decisions clarify the architecture.

| rank | ID | title | categories | priority | effort |
|---:|---|---|---|---|---|
| 5 | [AS-08](#as-08--fix-the-gateway-round-cap-boundary) | Fix the gateway round-cap boundary | bug, reliability | P1 | S |
| 6 | [AS-10](#as-10--parse-the-first-number-correctly) | Parse the first number correctly | bug | P1 | S |
| 7 | [AS-11](#as-11--distinguish-an-open-space-from-a-stale-space) | Distinguish an open space from a stale space | bug, reliability | P1 | S |
| 8 | [AS-09](#as-09--restore-reactivity-when-deletion-is-undone) | Restore reactivity when deletion is undone | bug, architecture | P1 | M |
| 9 | [AS-13](#as-13--turn-smoke-scripts-into-real-verification-gates) | Turn smoke scripts into real verification gates | testing, reliability | P1 | M |
| 10 | [AS-05](#as-05--coordinate-all-world-mutations) | Coordinate all world mutations | architecture, reliability | P1 | L |
| 11 | [AS-06](#as-06--decide-whether-automation-restrictions-are-policy-or-enforcement) | Decide whether automation restrictions are policy or enforcement | security, product, architecture | P1 | L |
| 12 | [AS-19](#as-19--make-the-base-prompt-a-tested-consistent-contract) | Make the base prompt a tested, consistent contract | testing, architecture, maintenance | P1 | M |

## Later

Real work, but not proposed as part of the next foundation milestone.

| rank | ID | title | categories | priority | effort |
|---:|---|---|---|---|---|
| 13 | [AS-12](#as-12--specify-whether-run-now-shifts-the-schedule) | Specify whether Run now shifts the schedule | product, bug | P2 | S |
| 14 | [AS-14](#as-14--introduce-a-provider-neutral-inference-boundary) | Introduce a provider-neutral inference boundary | architecture, reliability | P2 | L |
| 15 | [AS-15](#as-15--add-provenance-health-and-rollback-for-generated-artifacts) | Add provenance, health, and rollback for generated artifacts | architecture, feature, reliability | P1 | L |
| 16 | [AS-16](#as-16--make-tool-card-removal-match-its-visible-meaning) | Make tool-card removal match its visible meaning | ux, product, reliability | P2 | M |
| 17 | [AS-17](#as-17--preserve-history-when-system-messages-coalesce) | Preserve history when system messages coalesce | reliability, ux | P2 | S |
| 18 | [AS-18](#as-18--reduce-the-dependency-load-surface) | Reduce the dependency load surface | performance, maintenance, operations | P2 | M |
| 19 | [AS-20](#as-20--complete-the-open-source-readiness-pass) | Complete the open-source readiness pass | documentation, operations, product | P2 | M |

## Category views

These are alternate indexes over the same ordered backlog, not independent
queues. They make it possible to review one kind of work without losing the
cross-category priority order above.

| lens | items |
|---|---|
| Bugs and behavioral correctness | [AS-08](#as-08--fix-the-gateway-round-cap-boundary), [AS-09](#as-09--restore-reactivity-when-deletion-is-undone), [AS-10](#as-10--parse-the-first-number-correctly), [AS-11](#as-11--distinguish-an-open-space-from-a-stale-space), [AS-12](#as-12--specify-whether-run-now-shifts-the-schedule) |
| Security and authority | [AS-01](#as-01--authenticate-or-remove-the-local-evaluator), [AS-04](#as-04--treat-model-context-as-untrusted-bounded-data), [AS-06](#as-06--decide-whether-automation-restrictions-are-policy-or-enforcement), [AS-15](#as-15--add-provenance-health-and-rollback-for-generated-artifacts) |
| Reliability and persistence | [AS-02](#as-02--make-live-updates-verifiable-and-atomic), [AS-03](#as-03--define-persistence-and-recovery-semantics), [AS-05](#as-05--coordinate-all-world-mutations), [AS-08](#as-08--fix-the-gateway-round-cap-boundary), [AS-09](#as-09--restore-reactivity-when-deletion-is-undone), [AS-11](#as-11--distinguish-an-open-space-from-a-stale-space), [AS-13](#as-13--turn-smoke-scripts-into-real-verification-gates), [AS-15](#as-15--add-provenance-health-and-rollback-for-generated-artifacts), [AS-17](#as-17--preserve-history-when-system-messages-coalesce) |
| Operations and testing | [AS-01](#as-01--authenticate-or-remove-the-local-evaluator), [AS-02](#as-02--make-live-updates-verifiable-and-atomic), [AS-03](#as-03--define-persistence-and-recovery-semantics), [AS-13](#as-13--turn-smoke-scripts-into-real-verification-gates), [AS-18](#as-18--reduce-the-dependency-load-surface), [AS-19](#as-19--make-the-base-prompt-a-tested-consistent-contract), [AS-20](#as-20--complete-the-open-source-readiness-pass) |
| Architecture and evolution | [AS-03](#as-03--define-persistence-and-recovery-semantics), [AS-04](#as-04--treat-model-context-as-untrusted-bounded-data), [AS-05](#as-05--coordinate-all-world-mutations), [AS-06](#as-06--decide-whether-automation-restrictions-are-policy-or-enforcement), [AS-09](#as-09--restore-reactivity-when-deletion-is-undone), [AS-14](#as-14--introduce-a-provider-neutral-inference-boundary), [AS-15](#as-15--add-provenance-health-and-rollback-for-generated-artifacts), [AS-19](#as-19--make-the-base-prompt-a-tested-consistent-contract) |
| Product, feature, and UX | [AS-06](#as-06--decide-whether-automation-restrictions-are-policy-or-enforcement), [AS-12](#as-12--specify-whether-run-now-shifts-the-schedule), [AS-15](#as-15--add-provenance-health-and-rollback-for-generated-artifacts), [AS-16](#as-16--make-tool-card-removal-match-its-visible-meaning), [AS-17](#as-17--preserve-history-when-system-messages-coalesce), [AS-20](#as-20--complete-the-open-source-readiness-pass) |
| Performance and maintenance | [AS-04](#as-04--treat-model-context-as-untrusted-bounded-data), [AS-18](#as-18--reduce-the-dependency-load-surface), [AS-19](#as-19--make-the-base-prompt-a-tested-consistent-contract) |

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

## AS-08 — Fix the gateway round-cap boundary

**Status:** ready<br>
**Categories:** bug, reliability<br>
**Priority:** P1<br>
**Effort:** S<br>
**Dependencies:** none<br>
**Source:** repository review, 2026-07-09

### Problem and argument

If the model requests a tool in the last permitted round, the gateway executes
the mutation, appends its result, then exits the loop without letting the model
consume that result. The requested work can succeed while the user receives a
"Gave up" failure.

### Proposed outcome

Tool-execution budget and final-response inference have explicit, unsurprising
semantics.

### Acceptance criteria

- After the final permitted tool execution, the model can return one no-tool
  final response; or the final tool is refused before execution.
- A fake-transport test covers successful work at the exact boundary.
- No terminal failure can hide an already-successful final mutation without
  reporting that mutation clearly.

## AS-09 — Restore reactivity when deletion is undone

**Status:** candidate<br>
**Categories:** bug, architecture<br>
**Priority:** P1<br>
**Effort:** M<br>
**Dependencies:** none<br>
**Source:** reactive-widget delete/undo failure, 2026-07-06

### Problem and argument

Deletion unsubscribes a widget from the canvas announcer. Undo re-adds the same
instance but does not recreate subscriptions established inside generated
`initialize`, so the restored card is visible but inert. This violates the
combined behavior promised by first-class reactions and first-class undo.

### Proposed outcome

Reaction setup and teardown are explicit widget lifecycle operations. Undoing a
deletion restores behavior without duplicate subscriptions.

### Acceptance criteria

- Generated reactive widgets use a documented subscription lifecycle hook or
  a declarative canvas-mediated mechanism.
- Delete/undo restores fact and widget reactions.
- Repeated delete/undo cycles do not duplicate delivery.
- Old generated widgets have a migration or a clearly documented limitation.
- A regression test covers a reactive total or fact-backed widget.

## AS-10 — Parse the first number correctly

**Status:** ready<br>
**Categories:** bug<br>
**Priority:** P1<br>
**Effort:** S<br>
**Dependencies:** none<br>
**Source:** repository review, 2026-07-09

### Problem and argument

`AgentKnowledge class>>numberAt:` claims to return the first number but selects
every digit, dot, and minus sign in the fact body. For example, "between 10 and
20" becomes `1020` rather than `10`.

### Proposed outcome

The method implements its documented first-number contract. Typed facts remain
a possible later evolution rather than a prerequisite.

### Acceptance criteria

- A real scanner extracts the first complete numeric token.
- Tests cover integers, negatives, decimals, separators, multiple numbers,
  malformed text, and absent values.
- Non-numeric facts continue to answer `AgentUnknown`.

## AS-11 — Distinguish an open space from a stale space

**Status:** ready<br>
**Categories:** bug, reliability<br>
**Priority:** P1<br>
**Effort:** S<br>
**Dependencies:** none<br>
**Source:** repository review, 2026-07-09

### Problem and argument

`AgentCanvas>>isOpen` returns true whenever `space` is non-nil, although
`AgentCanvas>>open` explicitly recognizes non-nil stale/closed spaces. UI
helpers can consequently enqueue updates onto a space that will never pulse.

### Proposed outcome

The canvas distinguishes `hasSpace`, `isDisplayed`, and `isInteractive` where
those meanings differ, and background UI work never targets a dead space.

### Acceptance criteria

- `isOpen` reflects an actually opened/pulsing space.
- Callers use the predicate matching their real need.
- A closed or stale space followed by a background widget update is tested.
- Existing headless saved-image behavior remains working.

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

## AS-13 — Turn smoke scripts into real verification gates

**Status:** candidate<br>
**Categories:** testing, reliability, operations<br>
**Priority:** P1<br>
**Effort:** M<br>
**Dependencies:** AS-08, AS-10, AS-11<br>
**Source:** repository review and first hosted-CI experiment

### Problem and argument

Several `scripts/smoke-*.st` files print failure outcomes but still call
`Smalltalk exitSuccess`, so they are demonstrations rather than acceptance
gates. Some unit tests also prove helper behavior rather than the product
behavior they name. Hosted CI is deferred after a Linux `libgit2` crash, but a
trustworthy local verification command is still valuable.

### Proposed outcome

Deterministic checks fail reliably, paid/model-dependent evaluations report
structured evidence, and one local command provides an honest release signal.

### Acceptance criteria

- Every smoke script computes an explicit pass/fail outcome and exits
  accordingly.
- Deterministic tests and paid provider evaluations are separate suites.
- Provider evaluations record model, prompt revision, rounds, latency, cost,
  repairs, and outcome.
- Vacuous tests are replaced with assertions against actual widget state or
  behavior.
- A local `verify-all` workflow runs all non-paid gates.
- Hosted CI is revisited using a prebuilt dependency image or an upstream
  Pharo/Linux fix when collaboration makes it worthwhile.

## AS-14 — Introduce a provider-neutral inference boundary

**Status:** candidate<br>
**Categories:** architecture, reliability<br>
**Priority:** P2<br>
**Effort:** L<br>
**Dependencies:** AS-08, AS-19<br>
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
**Dependencies:** AS-03, AS-05, AS-13<br>
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
**Source:** completed self-built-tools phase and repository review

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

## AS-18 — Reduce the dependency load surface

**Status:** candidate<br>
**Categories:** performance, maintenance, operations<br>
**Priority:** P2<br>
**Effort:** M<br>
**Dependencies:** AS-13<br>
**Source:** clean-image verification output, 2026-07-09

### Problem and argument

The current default baselines load extensive Bloc/Toplo examples and tests and
emit a large volume of upstream undeclared-reference warnings. The suite still
passes, but build time, image/cache size, warning noise, and compatibility
surface are larger than the product requires.

### Proposed outcome

Fresh images load the smallest pinned runtime graph that supports the product,
while dependency tests/examples remain available only when deliberately
requested.

### Acceptance criteria

- Required upstream runtime packages/groups are identified explicitly.
- Default build and test paths avoid unused examples and upstream test suites.
- AgentSmalltalk's 144 current tests still pass after the reduction.
- Build duration, resulting image size, cache size, and warning count are
  measured before and after.

## AS-19 — Make the base prompt a tested, consistent contract

**Status:** candidate<br>
**Categories:** testing, architecture, maintenance<br>
**Priority:** P1<br>
**Effort:** M<br>
**Dependencies:** AS-04, AS-08<br>
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

## AS-20 — Complete the open-source readiness pass

**Status:** candidate<br>
**Categories:** documentation, operations, product<br>
**Priority:** P2<br>
**Effort:** M<br>
**Dependencies:** AS-02, AS-03, AS-13<br>
**Source:** open-source-readiness discussion, 2026-07-06

### Problem and argument

The repository has a strong experiment narrative but no license, limited
newcomer guidance, macOS-specific setup assumptions, no contribution guide,
and several load-bearing operational oddities that are easy to mistake for
cruft. Publishing before the persistence/update model is clear would invite
contributors into the most dangerous parts without a shared mental model.

### Proposed outcome

The repository can be used and contributed to by a newcomer without private
context or accidental loss of a living image.

### Acceptance criteria

- A deliberate license is present.
- The README includes a screenshot or short demonstration, supported-platform
  statement, architecture overview, disk/time expectations, and exact quick
  start.
- `CONTRIBUTING.md` explains `src/` versus generated image state, testing,
  update/build habits, and documentation responsibilities.
- `operations.md` explains `heal-in-image.st`, logs, backups, and recovery.
- Naming and internal phase jargon receive a newcomer-focused pass.
