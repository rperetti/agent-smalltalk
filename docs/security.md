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
| Canvas → model | Known facts, selected/full widget descriptions, capabilities, and automations are appended to the system prompt. | Canvas content is both disclosed and able to influence model behavior. |
| Model → image | `evaluate_smalltalk` executes generated source immediately. | Model output has the authority of the Pharo process. |
| Generated automation → later execution | Saved Smalltalk runs on its schedule without another model call. | Prompt restrictions are policy, not runtime enforcement. |
| Localhost → image | `AgentRemote` currently exposes `/update` and arbitrary `/eval` on port 8807 without authentication. | Any caller able to reach the listener may obtain image authority. |
| Image → disk | Snapshots, `.changes`, backups, and logs persist local state. | Local filesystem access exposes history and user data. |
| Generated/fetched content → prompt | Descriptions and selected content are concatenated into dynamic context. | Instruction-like data can become prompt injection. |

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
  image backups.
- Agent-owned background processes are named and terminated before snapshots
  and on startup.
- Automations must first run successfully before they can be enabled through
  the blessed workflow.
- Scheduled failures are contained, recorded, and posted visibly.
- Gateway fact-write screening requires each direct model-authored Fact body to
  be one decoded string literal whose complete value appears in the current
  user request; rejected writes are not evaluated.
- The base prompt forbids secrets in facts and discourages irreversible
  unattended behavior.

Each item above has important limits. For example, loopback is not caller
authentication, a timeout is not authority restriction, and a prompt rule does
not prevent edited Smalltalk from performing a forbidden operation.

## Known risks and planned work

| risk | consequence | backlog |
|---|---|---|
| Unauthenticated localhost `/eval` and `/update` | Another local caller may execute code or mutate the live image. | accepted for now; [AS-01](backlog.md#as-01--authenticate-or-remove-the-local-evaluator) |
| Incomplete checkpoint/backup unit | Unsaved work or matching source history may not be recoverable. | [AS-03](backlog.md#as-03--define-persistence-and-recovery-semantics) |
| Raw, unbounded dynamic prompt context | Prompt injection, unexpected disclosure, rising cost, or request failure. | [AS-04](backlog.md#as-04--treat-model-context-as-untrusted-bounded-data) |
| Mutations outside the gateway mutex | Updates, automations, snapshots, or generated code may race. | [AS-05](backlog.md#as-05--coordinate-all-world-mutations) |
| Automation restrictions exist only in prompt policy | Later unattended Smalltalk retains full process authority. | [AS-06](backlog.md#as-06--decide-whether-automation-restrictions-are-policy-or-enforcement) |
| Generated artifacts lack provenance and health | A failed or compromised run can leave persistent behavior that is difficult to audit. | [AS-15](backlog.md#as-15--add-provenance-health-and-rollback-for-generated-artifacts) |

The first row is accepted rather than scheduled. The evaluator is the only thing
that can question a live session, and both ways of closing the boundary cost
more than the exposure does while this remains a single-user experiment:
authenticating it puts ceremony between the operator and their own image, and
removing it trades away the visibility the experiment runs on. The terms are
recorded in AS-01, which is revisited if publication is ever on the table rather
than on a schedule.

## Data handling

- Every known fact is currently sent to the Anthropic Messages API on every
  request, regardless of selection.
- Notes and system messages are excluded from ordinary context but are sent
  when selected.
- Widget descriptions, selected slot/selector metadata, tool purposes and
  selectors, and automation descriptions are sent as prompt context.
- `logs/gateway.log` records user requests, evaluated code, tool results,
  errors, and complete HTTP request/response JSON. It currently has no rotation.
- Generated tools can make their own network requests to third-party services;
  their data handling is determined by generated source.
- Facts are visible and deletable, but there is currently no sensitivity label,
  provider scope, retention policy, or local-only fact mode.

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
