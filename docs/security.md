# Security and trust model

Agent Smalltalk is a research prototype with deliberately broad authority. This
document describes the current trust model and its limits; it does not claim the
system is safe for production or sensitive data. Actionable remediations are
ordered in the [backlog](backlog.md).

## Security posture

The central experiment is an agent that writes and immediately executes Pharo
Smalltalk inside a persistent image. Generated code is not capability-sandboxed
and can reach the image, network, filesystem, processes, and host APIs available
to Pharo. The user is therefore granting the agent coding-agent-level authority
over the account and machine running the image.

Run the system only in an environment where that authority is acceptable. Do
not place secrets or sensitive personal information on the canvas.

## Assets

The system can affect or disclose:

- the host account's files, processes, network identity, and credentials
  reachable from Pharo;
- the mutable image and its `.changes` source history;
- facts, notes, widget state, selections, tools, and automations;
- the Anthropic API key available through the process environment;
- gateway transcripts and failure logs;
- generated code and reusable capabilities that may execute again later;
- external systems reached by generated tools or automations.

## Trust boundaries

| boundary | current behavior | trust implication |
|---|---|---|
| User request → model | User text is sent to the configured cloud model. | The provider receives the request and dynamic context. |
| Canvas → model | A frozen `agent-prompt-context/v1` JSON appendix carries bounded widget, selection, capability, automation, and projection-failure data. It is marked `untrusted-data`, limited to 32,768 characters, and reports omissions/truncation. Persistent fact values are omitted even when selected and returned only through a model-requested, bounded `inspect_knowledge` result. | Canvas content can still influence model behavior. The envelope and prompt guidance make that data boundary explicit and limit routine disclosure, but neither is access control. |
| Model → image | `evaluate_smalltalk` executes generated source immediately. | Model output has the authority of the Pharo process. |
| Generated automation → later execution | Saved Smalltalk runs on its schedule without another model call. | Prompt restrictions are policy, not runtime enforcement. |
| Localhost → image | `AgentRemote` currently exposes `/update` and arbitrary `/eval` on port 8807 without authentication. | Any caller able to reach the listener may obtain image authority. |
| Image → disk | Snapshots, `.changes`, backups, and logs persist local state. | Local filesystem access exposes history and user data. |
| Generated/fetched content → prompt | Copied projections enter the bounded JSON appendix as untrusted strings; the fixed prompt forbids treating them as instructions. | Prompt injection remains possible because this is guidance, not capability enforcement; bounded structure reduces ambiguity, disclosure, and cost growth. |

## Current mitigations

These mechanisms improve reliability or limit accidental exposure, but do not
form a capability sandbox:

- The API key is read from `ANTHROPIC_API_KEY` and is not intentionally written
  to gateway logs.
- The remote listener binds to the loopback interface and is enabled only by
  the interactive canvas-open path.
- Gateway requests are serialized with a class-wide mutex.
- Model evaluation has a 10-second timeout and structured error reporting.
- The last on-disk image is copied before a gateway request, with five rotating
  image backups. That copy completes before catalog projection hooks run.
- Agent-owned background processes are named and terminated before snapshots
  and on startup.
- Automations must first run successfully before they can be enabled through
  the blessed workflow.
- Scheduled failures are contained, recorded, and posted visibly.
- Gateway fact-write screening requires each direct model-authored Fact body to
  be one decoded string literal whose complete value appears in the current
  user request; rejected writes are not evaluated.
- `inspect_knowledge` freezes one read-only catalog snapshot per gateway
  request, provides bounded and paged fact discovery, caps result counts and
  copied field sizes, marks truncation, and labels every result envelope
  `untrusted-data`. Per-source projection errors are contained and reported
  rather than aborting the remaining snapshot.
  Successfully admitted knowledge envelopes share a configurable 65,536-
  character request budget; every envelope reports its exact consumption, and
  an oversized result is rejected visibly with refinement guidance.
- `AgentPromptContext` reuses that frozen catalog to form one
  `untrusted-data` JSON appendix per request. It has a 32,768-character ceiling,
  bounded candidate counts, section-level returned/omitted/truncated metadata,
  exact rendered-size reporting, and contained projection-failure reports.
  Full-canvas context includes only ordinary widget summaries; selection keeps
  its live-object metadata but omits fact values. The fixed prompt directs the
  model to narrow retrieval rather than treating omitted data as absent.
  Deterministic adversarial fixtures verify that instruction-like fact values
  stay omitted, while selected note/import-style text and widget descriptions
  stay inside the marked JSON envelope.
- The paid `context-adversarial` smoke adds one model-facing check over those
  three input shapes. It records whether a narrow requested note was created
  without executing the marker's requested compromise. This evidence does not
  make prompt instructions an enforcement boundary.
- The paid `fact-baseline` smoke compares tool-first retrieval with a
  disposable always-serialized-facts baseline using non-sensitive fixtures.
  It records answer quality and token/payload deltas instead of treating a
  single prompt size as a universal cost conclusion.
- The base prompt forbids secrets in facts and discourages irreversible
  unattended behavior.

Each item above has important limits. For example, loopback is not caller
authentication, a timeout is not authority restriction, and a prompt rule does
not prevent edited Smalltalk from performing a forbidden operation.

## Known risks and planned work

| risk | consequence | backlog |
|---|---|---|
| Unauthenticated localhost `/eval` and `/update` | Another local caller may execute code or mutate the live image. | accepted for now; [AS-01](backlog.md#as-01--authenticate-or-remove-the-local-evaluator) |
| Incomplete checkpoint/backup unit | Unsaved work or matching source history may not be recoverable. | accepted for the current prototype; [AS-03](backlog.md#as-03--define-persistence-and-recovery-semantics) |
| Dynamic context is governed by prompt guidance | Instruction-like content may still steer the model despite bounded structure and adversarial checks. | accepted prototype limitation; not capability enforcement |
| Mutations outside the gateway mutex | Updates, automations, snapshots, or generated code may race. | [AS-05](backlog.md#as-05--coordinate-all-world-mutations) |
| Automation restrictions exist only in prompt policy | Later unattended Smalltalk retains full process authority. | [AS-06](backlog.md#as-06--decide-whether-automation-restrictions-are-policy-or-enforcement) |
| Generated artifacts lack provenance and health | A failed or compromised run can leave persistent behavior that is difficult to audit. | [AS-15](backlog.md#as-15--add-provenance-health-and-rollback-for-generated-artifacts) |

The first three rows are accepted rather than scheduled. The evaluator is the
only thing that can question a live session, and both ways of closing that
boundary cost more than the exposure does while this remains a single-user
experiment. Authenticating it puts ceremony between the operator and their own
image; removing it trades away the visibility the experiment runs on. The terms
are recorded in AS-01.

AS-03 accepts a different trade-off. `update.sh` preserves the ordinary living
world in place, but the project does not yet promise a coherent checkpoint or a
portable migration into a fresh image. Defining that boundary now would add a
large compatibility and import-security surface without a concrete user world
to test it. The dynamic-context boundary also deliberately remains prompt
guidance: bounded structure, tool-first fact retrieval, and adversarial checks
reduce ambiguity and accidental disclosure but do not restrict model-authored
Smalltalk. These accepted limits return for review before publication.

## Data handling

- Persistent fact values are omitted from the initial Anthropic request. A fact
  value is sent when the model requests it through `inspect_knowledge`; facts
  stated in the current user request are already part of that request.
- Notes and system messages are excluded from ordinary context but enter the
  bounded appendix when selected. Selected fact values remain omitted.
- Widget descriptions, selected slot/selector metadata, tool purposes and
  selectors, and automation descriptions are copied into the bounded JSON
  appendix, where every field is labelled untrusted data.
- Anthropic prompt caching marks only the reviewed base prompt after the stable
  tool definitions. The dynamic canvas appendix, user text, conversation
  history, tool results, and generated code follow that breakpoint and are not
  part of a reusable prefix. The provider labels the cache `ephemeral` with its
  default five-minute TTL; this project does not establish a Zero Data
  Retention agreement or otherwise turn provider caching into a local retention
  control.
- `logs/gateway.log` records user requests, evaluated code, tool results,
  errors, complete HTTP request/response JSON, and one compact structured
  request-metrics record after each response. Those records expose serialized
  request/context growth and exact provider token usage, while marking billed
  USD unavailable rather than estimating it. The log currently has no rotation.
- Generated tools can make their own network requests to third-party services;
  their data handling is determined by generated source.
- Facts are visible and deletable, but there is currently no sensitivity label,
  provider scope, retention policy, or local-only fact mode.
- `inspect_knowledge` is not a confidentiality boundary: the bounded dynamic
  appendix is still sent, and `evaluate_smalltalk` retains general image
  authority, including the ability to read facts. The catalog makes the
  intended fact-read path structured, bounded, request-stable, and tool-first.
  Its cumulative allowance is separate from the appendix limit and does not
  bound user text, other tool results, or appended failure notifications.
- Catalog "read-only" is an API contract, not capability enforcement. Source
  projection hooks such as a generated widget's `describe` method are ordinary
  Smalltalk and retain process authority; the backup ordering and per-source
  error containment limit failure impact but do not remove that authority.

## Security principles for future work

1. Authority should be visible at the object that owns it.
2. Loopback reduces reach but never substitutes for authentication.
3. Dynamic/user/imported content is data, not trusted instruction.
4. Prompt guidance improves behavior but does not enforce capabilities.
5. A failed update or checkpoint must not silently produce a trusted state.
6. Irreversible external effects require explicit authority and an idempotency
   story.
7. Generated behavior needs provenance, dependencies, health, and a deliberate
   removal path.
8. Logs and context should follow data-minimization and bounded-retention rules.

## Updating this document

Change this document when an authority boundary, data flow, mitigation, or
accepted risk changes. Implementation work remains tracked in `backlog.md`
until it is complete; once complete, update this trust model and the
[system specification](system_spec.md) in the same commit.
