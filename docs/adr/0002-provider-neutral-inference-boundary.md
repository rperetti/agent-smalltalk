# 0002 — Keep provider protocols outside the agentic loop

**Status:** accepted
**Date:** 2026-07-16
**Deciders:** Rodrigo Peretti
**Implements:** AS-14

## Context

Inference runs outside the image by ADR-0001, but the original gateway still
constructed Anthropic Messages payloads and interpreted their response blocks.
That made the core loop, model selection, credentials, and timeout behavior
provider-specific despite the external transport seam.

The loop needs one stable vocabulary for model text, tool use, and tool results.
Provider APIs differ in request envelopes, tool schemas, response shapes, usage
fields, cache controls, error formats, and connection lifetime.

## Decision

`AgentGateway` sends `agent-inference-request/v1` canonical turns through
`AgentInferenceProvider`. An adapter owns translation to and from one provider,
response validation, HTTP headers, resource closure, and usage translation.
Anthropic Messages remains the default adapter; OpenAI Chat Completions is the
second adapter.

`AgentInferenceProfile` owns provider, model, output limit, timeout, and retry
settings as named, inspectable image objects; `AgentGateway` uses the selected
profile or one supplied directly. Profiles contain no credentials: adapters
read the selected provider's API key from the process environment only when a
request is sent. The gateway retries only an adapter failure marked retryable,
before a response reaches the tool loop. A tool call therefore executes only
after one accepted provider response and is never replayed by retry logic.

## Alternatives considered

- **Leave Anthropic fields in `AgentGateway`.** Rejected: a nominal transport
  seam does not permit a second provider if the loop constructs one provider's
  protocol itself.
- **Normalize HTTP alone.** Rejected: payload and response translation are the
  provider coupling that matters to the tool loop, not merely client creation.
- **Retry after tool execution.** Rejected: a provider retry must never repeat
  an in-image mutation with full process authority.
- **Use provider caching as a common contract.** Rejected: cache controls and
  retention semantics differ. Each adapter reports its own behavior instead.

## Consequences

- Adding a provider means implementing and testing one adapter without changing
  the gateway loop.
- Users can inspect, retain, clone, and select non-secret profiles from the
  living image; rebuilding from pristine replaces those image objects.
- Selecting a provider can send canvas data to a different cloud service; the
  user must configure its credential and trust that service.
- Adapter tests must cover malformed responses and retry classification in
  addition to ordinary text and tool-use sequences.
- The default remains Anthropic so existing environments retain their model,
  credential, and prompt-cache behavior unless configured otherwise.

## Revisit when

- A local sidecar or in-image model can meet the generation-quality and latency
  requirements.
- Provider APIs require a richer canonical protocol than text and function-like
  tools.
- Evaluation evidence supports per-request provider or model routing.
