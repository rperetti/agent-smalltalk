# agent-smalltalk

A living agentic environment: an LLM writes Pharo Smalltalk that is compiled
live into a running image, materializing widgets on a spatial canvas.
See [docs/vision.md](docs/vision.md) for the full vision,
[docs/system_spec.md](docs/system_spec.md) for what is built and working
today, [docs/ideas.md](docs/ideas.md) for the parking lot of what's being
considered, and [docs/postponed.md](docs/postponed.md) for ideas worked out
then consciously deferred.

## Motivation: Breaking the Silos with a Living Agentic Environment

The spark for this project came from a simple realization: interacting with standard operating systems through APIs, rigid file structures, or screen-scraping feels like wearing a heavy pair of mittens. Everything is siloed. A true agentic OS wouldn't just tolerate an AI agent as a standalone application; the OS would be built around the agent's cognitive loop.

We found a blueprint for this in the legacy of Smalltalk. Smalltalk wasn't just a programming language; it was an entire living system. You didn't just write code for it — you lived inside it, modifying the system while it was running. By applying that philosophy to an AI agent, we can shift the paradigm from a static "chatbot" to a symbiotic operating environment.

**The vision — and where it stands today:**

* **Knowledge is Code** *(working today).* We blur the line between a fact (knowledge) and a tool (code). A note about your favorite coffee is an object; a script that orders that coffee is also an object. Because they share one environment, the agent links the two fluidly — no databases required. This is real now: facts live as editable objects on the canvas, and the agent writes its own reusable tools the same way.

* **An Evolving Ecosystem** *(working today).* The agent starts with generic capabilities and morphs into software tailored to your life. As it works, it writes reusable tools for itself instead of re-deriving the same things — accumulating competence over time. You're "programming" a personalized environment just by talking to it, correcting it, and sharing your digital life with it.

* **The Spatial Canvas** *(partly built, mostly the direction).* You shouldn't be the sole janitor of your digital workspace. Today the canvas is a shared space where both you and the agent place and manipulate objects, and you can lasso a cluster to hand the agent exactly the context you mean. From here, the aim is an agent that acts as an invisible spatial gardener — using semantic proximity to naturally group your digital life while you focus on the task at hand.

Pushing a concept to its limits to see where it breaks is how breakthrough systems get designed. This project is an experiment in building a useful place for a human and an agent to collaborate on expanding capabilities and knowledge. For a precise map of what runs today versus what's still ahead, see [what's built](docs/system_spec.md) and [the vision](docs/vision.md).


## ⚠️ Heads up — this is an experiment, with no guardrails

agent-smalltalk is a research prototype shared for the curious, **not a polished
or production-ready product**. Expect rough edges, bugs, and breaking changes;
there are no promises of stability or support.

Most importantly, **there are no guardrails, by design.** The whole premise is
an unconstrained living environment, so:

- The agent writes Smalltalk and **executes it immediately** in the running
  image, with full authority — there is *no sandbox*. It can run arbitrary
  code, make network requests, and touch anything in the image and, through
  it, your machine. Run it somewhere you're comfortable handing a coding agent
  the keys.
- Everything on the canvas — including any facts you tell it — is **sent to the
  Anthropic API on every request**. Don't put secrets or sensitive personal
  data in it.
- It calls the Anthropic API, so **it costs money** per request.

Treat it as a toy to explore, not a tool to depend on. No warranty; use at your
own risk — and have fun with it.

## Setup

1. Pharo 13 image + VM live in `pharo/` (gitignored). To fetch them:
   download `pharoImage-arm64.zip` and `pharo-vm-Darwin-arm64-stable.zip`
   from https://files.pharo.org/get-files/130/ and unzip into `pharo/`
   (VM into `pharo/vm/`).
2. `export ANTHROPIC_API_KEY=sk-ant-...` (needs API credits).

## Commands

| command | what it does |
|---|---|
| `./build.sh` | build a FRESH `pharo/Agent.image` from `src/` — destroys existing widgets/facts |
| `./update.sh` | reload tooling from `src/` into the LIVING image — world preserved; use this one |
| `./test.sh` | run the SUnit suite headless |
| `./run.sh` | open the Agent canvas (Cmd/Ctrl+Enter summons the spotlight bar) |

Headless one-shot ask:

```bash
./pharo/vm/Pharo.app/Contents/MacOS/Pharo --headless pharo/Agent.image \
  eval "AgentGateway ask: 'make me a counter widget'"
```

## Layout

- `src/` — Tonel packages (Core: gateway + sandbox; UI: canvas, widget, spotlight; Tests)
- `prompts/system.md` — the base prompt that teaches the model
  Pharo/Bloc and the AgentWidget contract. Treat it as code.
- `scripts/` — image build/test scripts run by the shell wrappers
- `logs/gateway.log` (gitignored) — append-only transcript of every agent
  request: loop events, evaluated code, results/errors, and full HTTP
  request/response JSON. In-image: `AgentGateway last log` for the most
  recent run. The API key is never logged.

## Acknowledgments

This project is an experiment in human–agent collaboration, and it was built
the same way. The idea and direction are Rodrigo Peretti's; the implementation (so far)
was a genuine collaboration with several AI models — **Claude Opus 4.8** and
**Claude Fable 5** (Anthropic) and **Gemini Pro** (Google) — pairing on the
design, the code, and the many debugging sessions along the way.

So the "we" throughout this README is literal: a project about a human and an
agent expanding their capabilities together, made by a human and several
agents doing exactly that. The commit history carries `Co-Authored-By`
trailers as a record of the partnership.
