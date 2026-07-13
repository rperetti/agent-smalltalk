# Vision

This document is the project's aspirational north star, not a claim that every
capability below exists today. See the [system specification](system_spec.md)
for current behavior, the [backlog](backlog.md) for actionable work, and the
[ideas incubator](ideas.md) for possibilities that are not yet ready to order.

## Philosophy

The goal is an operating environment where code and knowledge share one space,
and the user and agent work together in a persistent workspace that keeps
evolving — not a stateless chat window.

The bet is the living environment, not any single interface to it. The spatial
canvas described below is the current medium for touching it — a serious attempt,
not a fixed commitment. Smalltalk's own history is the precedent: the image
persisted while its interface changed — MVC, then Morphic, now Bloc. Like the
rest of the project, the medium is expected to keep evolving; the substrate is
the thesis.

### Core tenets

* **Persistent image.** Context is never lost. Code, memory, preferences, and
  tasks live in one continuously evolving graph: the Smalltalk image.
* **Knowledge is code.** Passive data and active capability are the same kind of
  thing. A note and an executable script are both addressable objects.
* **Live coding.** The system changes itself while running. The agent inspects,
  edits, and compiles code mid-execution without a restart.

## Architecture

The prototype pairs a Smalltalk image with a cloud frontier model.

* **Environment.** A native Pharo Smalltalk image. Everything in it is a live
  object.
* **Model.** A cloud frontier LLM (e.g. Anthropic Claude or OpenAI).
* **Gateway.** A Smalltalk class that manages the HTTP bridge: API keys, JSON
  payloads, and network latency.
* **Code extractor.** A method that parses the model's response and isolates
  compilable Smalltalk, dropping prose and Markdown.

## Execution loop

The model runs remotely, so the loop translates live memory into a text context
and turns text responses back into live objects. Running it in-image would be the
purist ideal; why it runs outside the image instead is recorded in
[ADR-0001](adr/0001-external-inference-boundary.md).

1. **Prompt.** The user requests a tool or action.
2. **Context mapping.** The environment packages the request with a lightweight
   text map of the available classes and objects.
3. **Inference.** The gateway sends the payload to the model over HTTP.
4. **Live compilation.** The image evaluates the returned Smalltalk immediately,
   instantiating any new class on the spot.

## The spatial canvas

The environment replaces the chat window and file tree with an infinite
spatial canvas that you and the agent share.

* **UI framework.** Built on Bloc, Pharo's low-level UI layer, which treats
  elements (`BlElement`) as nodes in a scene graph with vector graphics,
  animation, and zoom.
* **Spotlight.** A global shortcut opens a floating text bar. A typed command
  generates code, and the resulting widget appears under the cursor.
* **Direct manipulation.** Users drag and resize elements. Dragging a new input
  onto a generated widget rewrites its Smalltalk to match.
* **Spatial context.** Widget position carries meaning. A lasso around a cluster
  serializes only those objects to the model, which is how the context window
  is managed.

## Autonomous canvas management

The agent tends the canvas layout while the user focuses on the task.

* **Camera and teleport.** Asked for a distant widget, the agent pans the camera
  to it, or duplicates it into the current view.
* **Semantic clustering.** In the background, the agent groups related nodes by
  their context, using force-directed attraction.
* **Breadcrumb trails.** When it guides the user to a distant cluster, it leaves
  a connecting spline back to the previous location.

## Use cases

* **Persistent assistant.** A user says, "I'm working on the tax report." Three
  days later: "add this invoice to it." The agent knows the context and runs the
  script to process the invoice.
* **Conversational debugging.** A scraper fails because the page layout changed.
  The agent shows the code; the user says, "look for the div named
  sidebar-content"; the agent updates the tool mid-execution and finishes.
* **PDF to tracker.** A user drops a PDF on the canvas. The agent extracts
  concepts as clickable nodes. The user highlights one and types, "track
  mentions of this on Twitter"; the agent attaches the running script to the
  node.
* **Data that works.** A user drops an expense spreadsheet on the canvas and
  says, "make this trackable." The agent binds a dynamic chart to the file
  object, turning it into an application.
* **Visual programming.** A user draws a line from an "Email Inbox" node to a
  "To-Do List" widget. The agent writes the Smalltalk bridging them, popping up
  urgent emails as checkboxes.

## System prompt requirements

The system prompt in every request is the only mechanism for instructing the
model on how to operate the environment. It must:

1. **Name the environment.** Tell the model it is generating code for a live
   Pharo image that evaluates its output immediately.
2. **Output raw code.** Require syntactically valid Smalltalk only — no Markdown,
   explanation, or filler.
3. **Assume object uniformity.** Remind the model that everything is an object
   addressed by messages, and that it works by calling methods, not by querying
   a relational database.
