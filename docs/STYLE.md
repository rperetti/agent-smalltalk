# Writing style

The voice for this repo's prose and documentation. It applies to humans and to
any code agent or tool working here. Agents: see [AGENTS.md](../AGENTS.md), which
points back to this file.

## The register

Write like an experienced engineer maintaining a production system. Be concise,
precise, and technically accurate. Avoid marketing language, unnecessary
enthusiasm, filler, and repetition. Prefer practical guidance over theory,
explain tradeoffs honestly, and assume a technically competent reader. Every
sentence should introduce a concept, explain a decision, or help the reader do
something.

Keep it human, though — concise is not the same as cold. The target is
**concise, honest, warm, occasionally vivid; never corporate, never over-florid,
never clinically flat.**

## By document type

- **Functional docs** (operations, system spec, backlog, contributing, most of
  the README): the precise register above. This is the default.
- **Vision and motivation**: the same voice, with room for a single earned,
  concrete image where it makes an abstract point land. One image, not a pile of
  them. (The README's "mittens" line is the bar; "invisible spatial gardener"
  is over the line.)

## Cut on sight

- Marketing and hype: *powerful, seamless, robust, elegant, revolutionary,
  cutting-edge, symbiotic, leverage* as a verb.
- Throat-clearing openers: *The spark for this project…*, *It's worth noting…*
- Stacked metaphors and adjectives that restate one idea twice.
- Repetition across sections — say it once, in the section that owns it.

## Keep

- Honest limits and tradeoffs, stated plainly (*"no guardrails," "does not yet
  prove the recovery path"*).
- Concrete examples over abstractions (a coffee note, a counter widget).
- Understatement and the occasional light touch — warmth, not whimsy.

## A quick before/after

> **Before:** interacting with standard operating systems… feels like wearing a
> heavy pair of mittens. A true agentic OS wouldn't just tolerate an AI agent;
> the OS would be built around the agent's cognitive loop.
>
> **After:** Agents reach today's operating systems through APIs, file formats,
> and screen-scraping — like working in a heavy pair of mittens. This project
> starts from the opposite premise: build the environment around the agent
> instead of bolting the agent onto the environment.

The image survives; the jargon ("cognitive loop") and the padding do not.
