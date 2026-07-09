# Phase 6 Draft: The Agent Keeps Time

> **Status: DRAFT FOR REVIEW — not an implementation commitment.**
>
> **Recommendation:** add visible, pausable scheduled automations that run
> deterministic Smalltalk built by the agent and reuse its existing tools.
> Do **not** allow unattended LLM calls or irreversible external actions in
> this first version.

## Why this phase now

The system can remember facts, build reactive widgets, select live objects,
and accumulate reusable tools. It still acts only while the user is asking a
question. The next qualitative step is for useful behavior to continue on a
schedule: refresh a weather widget, check a read-only API, recompute a report,
or leave a message when something changes.

The important boundary is that **the model authors the routine once, while the
user is present; ordinary runs execute saved Smalltalk without invoking the
model again**. This makes cost and behavior legible. It also exercises the
image's deepest promise: code, schedule, state, UI, and history are all live
objects that persist together.

This phase is intentionally smaller than “an autonomous agent.” It proves that
the environment can initiate safe, inspectable work without quietly turning
into an unlimited background API spender.

## The money shot

1. The user has a fact-backed weather widget and a reusable
   `WeatherService`.
2. They ask: **“Refresh this every morning at 07:00.”**
3. The agent creates one automation that references the live widget and reuses
   `WeatherService`; a visible automation card shows its schedule and next run.
4. **Run now** updates the widget. Pause prevents a due run; Resume restores
   it.
5. Save, quit, and reopen: the automation still exists, exactly one scheduler
   resumes, and the next due run happens once.
6. Break the service: the automation reports a coalesced system message,
   records the failed run, and the scheduler continues serving other work.

No background LLM call is required for any scheduled run.

## What this phase should prove

1. **Agent-authored behavior can run without a prompt.**
2. **Autonomy is visible and controllable.** Every routine has a card,
   schedule, status, Run now, Pause/Resume, and delete.
3. **Existing capabilities compose.** Automations call `AgentTool` methods
   rather than regenerating fetch/parse logic.
4. **Scheduling survives the image lifecycle.** Save/reopen neither loses a
   routine nor duplicates its scheduler or execution.
5. **Failure is contained.** One failed routine cannot kill the scheduler,
   freeze the UI, or disappear silently.
6. **No surprise model bill.** The recurring path performs no LLM inference.

## Proposed design

### `AgentAutomation` — durable intent and run history (Core)

An automation is a registered live object. The agent may create a small
subclass for its behavior, while the base owns lifecycle state:

- `name` and one-line `purpose`;
- `schedule`;
- `enabled`;
- `nextRun`, `lastRun`, and `lastResult`;
- `lastError`;
- bounded run history (suggestion: newest 20);
- `runNow`, `pause`, `resume`, and `unregister`.

The generated subclass implements a narrow `run` method. The method may call
existing tools and update live objects, but scheduling, error capture, UI
dispatch, and history stay in hand-written code.

Suggested creation shape (exact API still open):

```smalltalk
AgentAutomation
	defineNamed: #MorningWeatherRefresh
	purpose: 'refresh my city weather each morning'.
```

Defining the class and registering/scheduling an instance should be separate
operations, matching the compiler discipline already learned for widgets and
tools.

Automations live in `AgentSmalltalk-Automations`, outside `src/`, and persist
with the user image. A hand-written registry is preferable to raw
`allInstances`: registration should be explicit, deletion meaningful, and
garbage instances irrelevant.

### `AgentSchedule` — small vocabulary, not cron

Start with two schedule forms:

- **interval:** every N minutes/hours;
- **daily:** at a local time.

The schedule answers `nextAfter:` and has a human-readable `describe`.
Inject the clock into scheduler tests; never make tests sleep.

For v1, daily means the machine's local timezone. A `#timezone` fact can
become a later enhancement, but mixing civil-time and user-fact semantics into
the first scheduler would inflate the phase.

### `AgentScheduler` — one supervised ticker

One hand-written scheduler:

- owns a single managed process named `agent-automation-scheduler`;
- starts on an interactive image session and is terminated before snapshots;
- polls registered automations on a modest cadence;
- atomically claims a due run before forking it, preventing duplicates;
- runs each automation in a named `agent-automation-*` process;
- catches every error and records it on the automation;
- posts/coalesces an `AgentSystemMessage` keyed by automation;
- dispatches UI mutations through the same safe UI path used by widgets.

The scheduler should expose a deterministic `tickAt:` method. Most behavior
can then be tested headlessly without a running timer.

### `AgentAutomationCard` — autonomy must have a face (UI)

A distinct card should show:

- name and purpose;
- schedule and next run;
- enabled/running/succeeded/failed state;
- last-run summary;
- **Run now**;
- **Pause / Resume**;
- delete;
- right-click source browsing.

Suggested color: muted purple, visually distinct from facts, notes, system
messages, tools, and ordinary widgets.

Open placement question: automation cards could form a strip along the bottom
edge, or live near the tool cards they orchestrate. I slightly prefer a
bottom-center **routines shelf**: tools are capabilities; automations are
ongoing commitments and deserve their own geography.

Deleting the card should unregister the automation instance. Whether it also
deletes a now-unused generated subclass can remain out of scope.

### Context and prompt contract

The gateway adds a compact `## Scheduled automations` section containing only:

- name;
- purpose;
- schedule;
- enabled/status;
- next/last run.

The base prompt teaches:

1. inspect existing automations before creating one;
2. reuse existing `AgentTool` capabilities;
3. keep `run` deterministic and bounded;
4. never call the LLM from an automation;
5. use live facts/references rather than copying literals;
6. verify with Run now before declaring success;
7. do not create an automation for a one-off request.

## Execution policy for v1

Allowed acceptance targets:

- read-only network fetches;
- computations;
- updates to image objects/widgets;
- system-message reporting.

Explicitly defer:

- sending email/messages or posting publicly;
- purchases and financial actions;
- arbitrary file deletion or shell commands;
- unattended LLM requests;
- workflows that wait for user input.

The environment still has no capability sandbox, so this is a prompt and
product boundary, not a security boundary. The acceptance examples should
stay read-only to avoid pretending otherwise.

## Image-closed semantics

When the Pharo image is closed, nothing runs. On reopen:

- do not replay every missed interval;
- compute the next future occurrence;
- optionally mark that runs were missed;
- never execute more than once merely because the image restarted.

This is honest and matches the image model. “Runs while the app is closed”
would require an external daemon and is a separate architectural phase.

## Acceptance tests

### Deterministic/headless

1. Registering an automation creates one registry entry and one card.
2. `tickAt:` runs a due enabled automation exactly once.
3. A second tick at the same time does not duplicate the run.
4. Paused and future automations do not run.
5. Run now records success and computes the next run.
6. A failing automation records the error, posts one coalescing system
   message, and does not stop another due automation.
7. Delete unregisters it; a deleted automation never runs.
8. Context lists active automations but omits implementation detail.
9. Scheduler startup is idempotent; snapshot cleanup terminates all scheduler
   and automation processes.
10. A fake clock proves interval and daily `nextAfter:` behavior without
    sleeping.

### Live-model/headless smoke

1. Create or reuse `WeatherService`.
2. Ask for a two-minute weather refresh automation.
3. Assert one automation exists, its generated `run` references
   `WeatherService`, and Run now succeeds without a model call.
4. Ask to pause/resume/change the schedule; assert the same automation is
   modified rather than duplicated.

### GUI/manual

1. Card status, buttons, and countdown/next-run text update correctly.
2. Run now visibly updates the target widget.
3. Pause blocks a due run; Resume allows the next one.
4. Right-click opens generated automation source.
5. Save/reopen preserves the routine and starts exactly one scheduler.
6. A forced failure produces a readable system message while the UI remains
   responsive.

## Non-goals

- Autonomous or scheduled LLM inference.
- Natural-language cron completeness.
- Running while the image is closed.
- Catch-up execution of every missed run.
- Parallel execution policies beyond “one run per automation at a time.”
- Approval workflows and actionable inbox messages.
- OS notifications.
- General event triggers (“when an email arrives”)—schedule first.
- Tool health/versioning/curation.

## Risks to design around

- **Duplicate runs after resume.** Claim/update run state before execution.
- **Serialized processes.** Use managed names and terminate before snapshot,
  then restart from durable schedule data.
- **UI work from background processes.** Route through safe UI dispatch.
- **Slow/hung work.** Give each run a timeout and surface it as state.
- **Overlapping intervals.** Do not start a second run while one is active.
- **Invisible cost.** No LLM calls; cards make network cadence explicit.
- **Stale live references.** A missing target should fail visibly, not
  silently recreate or retarget itself.
- **Card clutter.** One card per registered routine; coalesce failure
  messages.

## Alternatives for Phase 6

### A. Trustworthy toolbox

Add generated self-tests, health state, dependencies, curation, forget, and
version/history to `AgentTool`. This is the conservative choice and may be the
right one if accumulated capabilities already feel unreliable. It deepens
Phase 5 rather than opening a new product surface.

### B. App-grade canvas objects

Introduce `AgentApp` with a model/view split and a `ToInnerWindow` or Spec2
container. Choose this if an actual request has outgrown the 240×160 widget
contract. Without such a request, the design risks being framework-led.

### C. Conversation provenance

Give notes parent links so Reply includes a whole thread automatically. This
is small, useful, and low-risk, but it does not advance the system's central
“living capabilities” thesis as much as automation or toolbox trust.

### Recommendation

Choose scheduled automations if the next goal is a visible leap toward the
agentic-OS vision. Choose trustworthy toolbox first if the recent weather
debugging made reliability feel more urgent than autonomy. I would choose
**scheduled automations with the strict no-background-LLM boundary**, while
keeping toolbox trust as the next likely phase or a small prerequisite pass.

## Questions for review

1. Is “no unattended LLM calls” the right Phase 6 boundary?
2. Should v1 support both interval and daily schedules, or interval only?
3. Should closing the image simply skip missed runs, or post one “missed”
   message on reopen?
4. Should deleting an automation card unregister it immediately, with normal
   canvas undo restoring registration?
5. Where should automation cards live: bottom-center routines shelf, near
   tools, or wherever the agent places them?
6. Should every successful run leave history only on the card, or also create
   a system message? My preference: card history on success, system message
   only on failure or a meaningful detected change.
7. Do we want a short toolbox-health prerequisite before this phase, or learn
   what trust features are needed by putting tools under scheduled reuse?

