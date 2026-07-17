# 0001 — Inference runs outside the image, behind the gateway

**Status:** accepted
**Date:** 2026-07-13
**Deciders:** Rodrigo Peretti
**Related ADR:** [0002 — Provider-neutral inference boundary](0002-provider-neutral-inference-boundary.md)

## Context

The purist form of a Smalltalk-inspired living environment would run the model
*inside* the image: inference would be another message send, and code, knowledge,
and the model would share one object space. That is the ideal this project points
at.

No frontier-quality model runs usefully inside a Pharo image today. The capable
models are large, GPU-bound, and served remotely. Running the code-generation
loop against a model small enough to embed would trade away the capability the
whole prototype depends on. So the first prototype accepts a boundary: it calls
out to a remote model over HTTP.

## Decision

Inference lives outside the image, behind `AgentGateway`. The gateway owns the
bridge to a configured provider, serializes canvas context into a text prompt,
runs the tool-use loop, and turns responses back into live objects. The image
remains the substrate for everything else — code,
knowledge, widgets, automations, and state — but the model itself is a remote
service reached through one seam.

## Alternatives considered

- **In-image model (the purist ideal).** Run a model within Pharo so inference is
  a local message send. Rejected for now: no model that runs in-image is good
  enough for the generation task, and Pharo has no GPU integration to host one.
  This is the option the decision consciously defers, not dismisses.
- **Local model as a sidecar** (e.g. a local server reached over HTTP). Keeps the
  same gateway boundary but runs the model on the same machine. Compatible with
  this decision and not precluded — it slots in behind the gateway — but current
  local models are below frontier capability for code generation, so it is not
  the default. The provider-neutral boundary in ADR-0002 keeps this option
  available without putting sidecar details in the agent loop.
- **Embedding a small model directly in the image.** Rejected on capability
  grounds; it would bound the experience to whatever fits in-process.

## Consequences

- **Easier:** frontier-model capability with no GPU or model infrastructure in
  the image; a single seam (`AgentGateway`) for logging, redaction, retries, and
  future provider swaps.
- **Required:** canvas state must be serialized to a text context on every
  request and responses re-materialized into objects (the execution loop). The
  context window becomes a real constraint, which is what motivates lasso and
  selection scoping.
- **Harder / accepted costs:** per-request latency, provider cost, and provider
  availability become part of the UX; everything on the canvas is sent to a
  third party on every request (see [security.md](../security.md)); the
  environment is not self-contained or offline.
- **Deliberately unsupported for now:** a fully self-contained image with no
  external dependency, and true "inference as a message send."

## Revisit when

- A model good enough for the generation task can run locally — in-image or as a
  sidecar — within acceptable latency and resource budgets.
- Privacy, offline operation, or cost requirements come to outweigh frontier
  capability.
- A local backend is added behind the provider-neutral gateway boundary.
