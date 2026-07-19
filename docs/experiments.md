# Experiments

The durable record of what Agent Smalltalk is trying to learn. The project is a
research prototype; an experiment should change what we believe about the
living environment, not merely demonstrate that one generated example worked.

The central question is:

> Does the environment get better through use, or does it merely accumulate
> state?

Experiment records retain hypotheses, prior evidence, protocols, observations,
limits, and decisions. Implementation needed to run an experiment belongs in
the [backlog](backlog.md). Unvalidated product possibilities belong in
[ideas.md](ideas.md). Implemented behavior belongs in
[system_spec.md](system_spec.md).

## Method

Use a lightweight scientific method suited to an exploratory software system:

1. Scope the relevant literature before fixing the protocol.
2. State a falsifiable hypothesis and a credible competing hypothesis.
3. Choose controls, measures, repetitions, and the spending limit before the
   run.
4. Record observations separately from interpretation.
5. Conclude `supported`, `not supported`, or `inconclusive`; do not turn every
   outcome into a success story.
6. Update the backlog, ideas, or project direction when the evidence warrants
   it.

Mark each record as **exploratory** or **confirmatory**. Exploratory work finds
variables and generates sharper hypotheses. Confirmatory work uses a fixed
protocol that could disconfirm a result seen earlier. Small samples and hosted
model drift limit certainty; reproducibility means preserving the protocol,
fixtures, system revisions, intervention records, and evidence, not
expecting identical generations.

### Prior evidence and platform implications

The literature pass is a bounded scoping review, not an open-ended gate. Record
the search date, scope, representative primary sources, established results,
conflicting evidence, and the remaining local question.

Each review also produces a platform disposition:

| disposition | meaning |
|---|---|
| Already present | The platform already follows the supported pattern. |
| Backlog candidate | The evidence is relevant, exposes a local gap, and supports a concrete outcome. |
| Local experiment first | The technique is promising, but transfer to this environment is uncertain. |
| Do not adopt | The evidence is weak, conflicting, irrelevant, or the technique adds unjustified machinery. |

External evidence can justify a backlog candidate, not silent adoption. Preserve
the current revision as a baseline, run a small local comparison, and make the
new behavior the baseline only if it survives that check. Evidence-derived
backlog items name both the external support and the remaining local
uncertainty.

### Evidence handling

For each paid or nondeterministic run, record the repository commit, prompt
revision, pinned model and provider, inference settings, fixture, date,
repetition count, budget, and semantic checks. Prefer deterministic fixture
scripts over hand-made image state.

Human intervention is part of the experiment, not background noise. Record any
human action during a measured run that changes its context, world state,
evaluation, or next action. Classify it as protocol-required, discretionary, or
post-run curation; record zero explicitly when none occurred. A protocol task
prompt is not an intervention, but an ad hoc clarification, correction, retry,
manual edit, context selection, cleanup, or acceptance decision is.

Each intervention event identifies the run, condition, task step, category,
trigger, action, affected state or artifact, whether the agent could observe it,
result, and approximate effort. Do not capture every pointer action or private
content. Post-run curation cannot change the measured result, and a run with a
meaningful unrecorded intervention has incomplete evidence.

`logs/gateway.log` contains full prompts and canvas content and remains local.
Version scripts, safe fixtures, redacted machine-readable results, aggregates,
and the interpretation. Never commit secrets or private canvas data merely to
make an experiment reproducible.

### Record shape

Each experiment should contain:

- status, mode, dates, and related backlog items;
- question and decision it informs;
- prior evidence and the unresolved gap;
- hypothesis, competing hypothesis, and what would change our mind;
- protocol, controls, human-intervention policy, semantic checks, repetitions,
  and budget;
- observations and results;
- intervention events, including an explicit zero when applicable;
- interpretation, limitations, decision, and next question;
- links to scripts, revisions, and safe evidence.

---

## EXP-01 — Does a living world improve through use?

**Status:** planned<br>
**Mode:** exploratory<br>
**Dates:** not started<br>
**Related backlog:** AS-32, AS-33, AS-34, AS-35; AS-28 follows<br>
**Decision informed:** whether accumulated facts, executable capabilities, and
live state deserve to remain the project's central substrate

### Question

When factual memory, executable procedures, live object state, and human
correction co-evolve in one image, do they produce compounding capability or
compounding interference?

### Prior evidence

Initial scoping review: 2026-07-18. This is a starting map, not a systematic
review.

Reusable procedural memory and executable skill libraries have improved task
success or efficiency in several environments:

- [Voyager](https://arxiv.org/abs/2305.16291) accumulates and reuses executable
  skills in an embodied environment.
- [Large Language Models as Tool Makers](https://arxiv.org/abs/2305.17126)
  amortizes expensive tool creation across cheaper reuse.
- [ExpeL](https://arxiv.org/abs/2308.10144) and
  [Agent Workflow Memory](https://arxiv.org/abs/2409.07429) reuse distilled
  experience and workflows across tasks.
- [SkillCraft](https://arxiv.org/abs/2603.00718) evaluates acquired tool
  compositions and also shows that low-quality saved skills can increase work.

Long-term and continual-memory evaluations expose the other side:

- [LongMemEval](https://arxiv.org/abs/2410.10813) tests multi-session reasoning,
  updates, temporal reasoning, and abstention rather than recall alone.
- [LifelongAgentBench](https://arxiv.org/abs/2505.11942) reports limited benefit
  from ordinary experience replay when irrelevant information and context
  pressure accumulate.
- [Mem2ActBench](https://arxiv.org/abs/2601.19935) distinguishes remembering a
  fact from applying it to an underspecified tool action.
- [STALE](https://arxiv.org/abs/2605.06527) tests whether an agent rejects old
  assumptions after later evidence invalidates them.
- [AgentMemoryBench](https://openreview.net/pdf?id=MSXbrNExax) studies factual
  and procedural memory together, including transfer, forgetting, repair, and
  contamination between memory types.

Two recent adjacent systems narrow the gap further:

- [User as Code](https://arxiv.org/abs/2606.16707) represents user state and
  rules as an evolving executable software project rather than a bag of facts.
- [Persistent AI Agents in Academic Research](https://arxiv.org/abs/2605.26870)
  treats the persistent human-agent environment as the unit of observation and
  argues for artifact- and correction-level measures. It is a descriptive case
  study, not causal evidence.

For evaluation design, [tau-bench](https://arxiv.org/abs/2406.12045) checks the
resulting environment state and repeats trials to expose inconsistent agent
behavior.

The generic claims that memory and reusable tools can help are therefore not
new. The unresolved question is what happens when factual memory, executable
procedures, generated UI, live object state, and human edits share one
inspectable image and evolve together.

### Platform implications

The review produced four actionable gaps:

- AS-32 adds longitudinal, state-checked evaluation fixtures.
- AS-33 gives accumulated capabilities a minimal qualification and retirement
  lifecycle.
- AS-34 replaces bounded alphabetical capability exposure with selective
  discovery as the toolbox grows.
- AS-35 preserves fact revisions while keeping one unambiguous current value.

The existing typed separation among facts, capabilities, automations, and
ordinary canvas objects; on-demand fact retrieval; frozen request snapshots;
and executable reusable tools already follow useful patterns from the
literature. Do not add generic transcript replay or an undifferentiated vector
store without evidence that the current structured boundary is insufficient.

### Hypothesis

Across related tasks, a world containing both current factual memory and
verified procedural memory will reuse prior work, require fewer model rounds and
less generated code, and preserve or improve semantic success relative to a
fresh world.

### Competing hypothesis

Additional state will create ambiguous retrieval, stale assumptions, poor tool
reuse, and hidden dependencies. Corrections and repairs will rise enough to
cancel or exceed the benefit of reuse.

### What would change our mind

Evidence against compounding value would be a combined world that fails to
improve reuse, success, or effort over the relevant single-memory conditions,
or that gains efficiency only by increasing correction and stale-state errors.
Evidence against accumulation as the dominant harm would be consistent semantic
success and reuse without a rising correction burden as the task sequence and
world grow. A scenario that cannot distinguish memory effects from basic model
failure is inconclusive, not negative evidence about persistence.

### Proposed protocol

Use a two-by-two comparison before adding model choice as another variable:

| | no procedural memory | procedural memory |
|---|---|---|
| no factual memory | fresh baseline | verified capabilities only |
| factual memory | current facts only | combined living world |

For every condition:

- build the state from a deterministic script in a disposable image;
- hold the model, provider, prompt revision, platform revision, generation
  settings, and task sequence constant;
- use related tasks that require factual application, capability creation and
  reuse, live modification, and correction;
- check final objects, source, state, subscriptions, and behavior rather than
  grading prose alone;
- repeat enough times to expose inconsistency, with the count and spending limit
  chosen before the paid run;
- fix the allowed human-intervention policy before the run and record every
  protocol-required, discretionary, and post-run event;
- preserve one small current-platform baseline before changing capability or
  fact behavior, then test each evidence-backed platform change as an ablation.

The exact task sequence, human-intervention policy, semantic checks,
repetitions, and budget remain to be fixed before the experiment starts.

### Measures

- semantic pass and repeated-run consistency;
- model rounds, repairs, latency, token use, and calculated cost;
- reused, duplicated, abandoned, and superseded artifacts;
- retrieval misses, retrieved-but-unused state, wrong-tool reuse, and needless
  tool creation;
- protocol-required and discretionary human interventions, their approximate
  effort, and successful agent repairs after them;
- stale-state, invalidation, and dependency failures;
- cost and correction burden per accepted artifact.

### Results

Not run.

### Interpretation and decision

Pending.

## Candidate follow-up experiments

These questions do not yet have fixed protocols or experiment IDs:

- Compare a baseline model and one or two challengers across both fresh and
  evolved worlds after EXP-01 establishes the state effect (AS-28).
- Test whether a verified agent-written capability can replace the equivalent
  hand-written base-prompt recipe without reducing success.
- Test a strong model as capability author and a cheaper model as capability
  user before building a general model router.
- Compare flat string facts with typed executable user state before changing the
  fact model.
- Compare durable code/test improvements with automatically distilled textual
  lessons from failures; do not assume more prose memory is better.
- Promote one useful living-world capability into versioned platform source by
  hand and record where the boundary fails before building a general pipeline.
- Add a minimal failed-run debug capsule only if missing diagnostics block the
  experiments; do not pre-build a general observability surface.
